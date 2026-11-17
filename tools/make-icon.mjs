// Generates the app icon without any image library: the brand gradient tile
// with a soft white blob and a terminal prompt (">_") cut into it — the same
// composition as brand/mark.svg, drawn pixel by pixel.
// Usage: node tools/make-icon.mjs [size]
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const size = Number(process.argv[2] || 1024);
const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(here, '..', 'App', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png');

const px = Buffer.alloc(size * size * 4);
const s = size / 1024;

const lerp = (a, b, t) => a + (b - a) * t;
const smooth = (edge0, edge1, x) => {
  const t = Math.min(1, Math.max(0, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
};
const clamp = (v) => Math.max(0, Math.min(255, Math.round(v)));

function segmentDistance(x, y, ax, ay, bx, by) {
  const vx = bx - ax;
  const vy = by - ay;
  const wx = x - ax;
  const wy = y - ay;
  const len = vx * vx + vy * vy;
  const t = len === 0 ? 0 : Math.min(1, Math.max(0, (wx * vx + wy * vy) / len));
  const dx = x - (ax + vx * t);
  const dy = y - (ay + vy * t);
  return Math.sqrt(dx * dx + dy * dy);
}

function roundedBoxDistance(x, y, cx, cy, half, radius) {
  const qx = Math.abs(x - cx) - half + radius;
  const qy = Math.abs(y - cy) - half + radius;
  const outside = Math.hypot(Math.max(qx, 0), Math.max(qy, 0));
  const inside = Math.min(Math.max(qx, qy), 0);
  return outside + inside - radius;
}

// layout in 1024-space
const blobC = 512 * s;
const blobHalf = 300 * s;
const blobRadius = 112 * s;
const stroke = 56 * s;

const chevron = [
  [398 * s, 392 * s, 512 * s, 512 * s],
  [512 * s, 512 * s, 398 * s, 632 * s],
];
const underscore = [552 * s, 632 * s, 662 * s, 632 * s];

for (let y = 0; y < size; y += 1) {
  for (let x = 0; x < size; x += 1) {
    const t = (x / size) * 0.55 + (y / size) * 0.45;
    let r = lerp(38, 87, t);
    let g = lerp(70, 224, t);
    let b = lerp(255, 184, t);

    const dx = x / size - 0.24;
    const dy = y / size - 0.20;
    const glow = Math.max(0, 1 - Math.sqrt(dx * dx + dy * dy) / 0.6);
    r += 22 * glow;
    g += 20 * glow;
    b += 14 * glow;

    // soft white blob
    const sd = roundedBoxDistance(x, y, blobC, blobC, blobHalf, blobRadius);
    const blob = 1 - smooth(-2 * s, 2 * s, sd);
    if (blob > 0) {
      r = lerp(r, 255, blob);
      g = lerp(g, 255, blob);
      b = lerp(b, 255, blob);
    }

    // prompt glyph inside the blob
    let d = Infinity;
    for (const [ax, ay, bx, by] of chevron) d = Math.min(d, segmentDistance(x, y, ax, ay, bx, by));
    d = Math.min(d, segmentDistance(x, y, underscore[0], underscore[1], underscore[2], underscore[3]));
    const glyph = (1 - smooth(stroke - 2 * s, stroke + 2 * s, d)) * blob;
    if (glyph > 0) {
      r = lerp(r, 11, glyph);
      g = lerp(g, 11, glyph);
      b = lerp(b, 15, glyph);
    }

    const i = (y * size + x) * 4;
    px[i] = clamp(r);
    px[i + 1] = clamp(g);
    px[i + 2] = clamp(b);
    px[i + 3] = 255;
  }
}

// PNG encode: filter byte 0 per scanline, RGBA8
const raw = Buffer.alloc((size * 4 + 1) * size);
for (let y = 0; y < size; y += 1) {
  raw[y * (size * 4 + 1)] = 0;
  px.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
}

const crcTable = new Int32Array(256);
for (let n = 0; n < 256; n += 1) {
  let c = n;
  for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  crcTable[n] = c;
}
const crc32 = (buf) => {
  let c = 0xffffffff;
  for (const byte of buf) c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(size, 0);
ihdr.writeUInt32BE(size, 4);
ihdr[8] = 8;
ihdr[9] = 6;
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log(`wrote ${out} (${size}×${size}, ${(png.length / 1024).toFixed(1)} KB)`);
