// Generates the app icon without any image library: a dark gradient square
// with a terminal prompt mark (">_" ), written as a PNG through node:zlib.
// Usage: node tools/make-icon.mjs [size]
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const size = Number(process.argv[2] || 1024);
const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(here, '..', 'App', 'Assets.xcassets', 'AppIcon.appiconset', 'AppIcon-1024.png');

const px = Buffer.alloc(size * size * 4);

const lerp = (a, b, t) => a + (b - a) * t;
const smooth = (edge0, edge1, x) => {
  const t = Math.min(1, Math.max(0, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
};
// distance from point to a segment
function segmentDistance(px_, py, ax, ay, bx, by) {
  const vx = bx - ax;
  const vy = by - ay;
  const wx = px_ - ax;
  const wy = py - ay;
  const len = vx * vx + vy * vy;
  const t = len === 0 ? 0 : Math.min(1, Math.max(0, (wx * vx + wy * vy) / len));
  const dx = px_ - (ax + vx * t);
  const dy = py - (ay + vy * t);
  return Math.sqrt(dx * dx + dy * dy);
}

const s = size / 1024;
const stroke = 58 * s;
const segments = [
  [290 * s, 720 * s, 290 * s, 280 * s],
  [290 * s, 280 * s, 710 * s, 720 * s],
  [710 * s, 720 * s, 710 * s, 280 * s],
];
const dot = { x: 770 * s, y: 250 * s, r: 26 * s };

for (let y = 0; y < size; y += 1) {
  for (let x = 0; x < size; x += 1) {
    const t = (x / size) * 0.55 + (y / size) * 0.45;
    let r = lerp(38, 87, t);
    let g = lerp(70, 224, t);
    let b = lerp(255, 184, t);

    const dx = x / size - 0.22;
    const dy = y / size - 0.18;
    const glow = Math.max(0, 1 - Math.sqrt(dx * dx + dy * dy) / 0.55);
    r += 26 * glow;
    g += 22 * glow;
    b += 18 * glow;

    let d = Infinity;
    for (const [ax, ay, bx, by] of segments) d = Math.min(d, segmentDistance(x, y, ax, ay, bx, by));
    const coverage = 1 - smooth(stroke - 1.5 * s, stroke + 1.5 * s, d);

    if (coverage > 0) {
      r = lerp(r, 255, coverage);
      g = lerp(g, 255, coverage);
      b = lerp(b, 255, coverage);
    }

    const dd = Math.hypot(x - dot.x, y - dot.y);
    const dotCoverage = 1 - smooth(dot.r - 1.5 * s, dot.r + 1.5 * s, dd);
    if (dotCoverage > 0) {
      r = lerp(r, 11, dotCoverage * 0.78);
      g = lerp(g, 11, dotCoverage * 0.78);
      b = lerp(b, 15, dotCoverage * 0.78);
    }

    const i = (y * size + x) * 4;
    const clamp = (value) => Math.max(0, Math.min(255, Math.round(value)));
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
ihdr[8] = 8; // bit depth
ihdr[9] = 6; // RGBA
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log(`wrote ${out} (${size}×${size}, ${(png.length / 1024).toFixed(1)} KB)`);
