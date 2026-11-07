#!/usr/bin/env node
/**
 * Tiebanana 图标构建脚本
 *
 *   node docs/icon/build_icons.js preview            # 生成各调色板预览页面
 *   node docs/icon/build_icons.js build <palette>    # 输出 android / ios / assets 全套图标
 *
 * 依赖：本机 Chrome（headless 渲染 SVG）。字形轮廓已内联在 tiebanana.svg 中，无需字体。
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const zlib = require('zlib');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..', '..');
const SVG = path.join(__dirname, 'tiebanana.svg');
const WIP = path.join(__dirname, '_wip');
const CHROME_CANDIDATES = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];

function dataUri(file) {
  return 'data:image/png;base64,' + fs.readFileSync(file).toString('base64');
}

// ---- 墨迹测量：把圆形/自适应前景的内容缩放到不越出容器 ----------------------
function decodePng(file) {
  const b = fs.readFileSync(file);
  if (b.readUInt32BE(0) !== 0x89504e47) throw new Error('不是 PNG: ' + file);
  const w = b.readUInt32BE(16), h = b.readUInt32BE(20);
  if (b[24] !== 8 || b[25] !== 6) throw new Error('需要 8bit RGBA PNG');
  let off = 8, idat = [];
  while (off + 8 <= b.length) {
    const len = b.readUInt32BE(off);
    const type = b.toString('ascii', off + 4, off + 8);
    if (type === 'IDAT') idat.push(b.subarray(off + 8, off + 8 + len));
    if (type === 'IEND') break;
    off += 12 + len;
  }
  const stride = w * 4;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const img = Buffer.alloc(h * stride);
  const paeth = (a, b2, c) => {
    const p = a + b2 - c, pa = Math.abs(p - a), pb = Math.abs(p - b2), pc = Math.abs(p - c);
    return (pa <= pb && pa <= pc) ? a : (pb <= pc ? b2 : c);
  };
  let p = 0;
  for (let y = 0; y < h; y++) {
    const filter = raw[p++];
    const line = raw.subarray(p, p + stride);
    p += stride;
    const out = img.subarray(y * stride, (y + 1) * stride);
    const prev = y ? img.subarray((y - 1) * stride, y * stride) : null;
    if (filter === 0) line.copy(out);
    else if (filter === 1) {
      for (let i = 0; i < stride; i++) out[i] = (line[i] + (i >= 4 ? out[i - 4] : 0)) & 0xff;
    } else if (filter === 2) {
      for (let i = 0; i < stride; i++) out[i] = (line[i] + (prev ? prev[i] : 0)) & 0xff;
    } else if (filter === 3) {
      for (let i = 0; i < stride; i++) {
        out[i] = (line[i] + (((i >= 4 ? out[i - 4] : 0) + (prev ? prev[i] : 0)) >> 1)) & 0xff;
      }
    } else {
      for (let i = 0; i < stride; i++) {
        out[i] = (line[i] + paeth(i >= 4 ? out[i - 4] : 0, prev ? prev[i] : 0, (prev && i >= 4) ? prev[i - 4] : 0)) & 0xff;
      }
    }
  }
  return { width: w, height: h, data: img };
}

let cachedInkRadius = null;
/** 内容（无背景层）在 1024 画布中的墨迹最大半径，用来算圆形/安全区缩放 */
function inkRadius() {
  if (cachedInkRadius === null) return initInkRadius();
  return cachedInkRadius;
}

function initInkRadius() {
  if (cachedInkRadius !== null) return cachedInkRadius;
  const tmp = path.join(os.tmpdir(), 'tiebanana-ink-measure.png');
  render(svgFor('indigo', 'stripped'), 256, tmp);
  const { width, height, data } = decodePng(tmp);
  let rmax = 0;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (data[(y * width + x) * 4 + 3] > 8) {
        const r = Math.hypot(x + 0.5 - width / 2, y + 0.5 - height / 2);
        if (r > rmax) rmax = r;
      }
    }
  }
  cachedInkRadius = rmax * (1024 / width);
  return cachedInkRadius;
}

/** 圆形图标：内容相对方形满幅版的缩放系数，保证墨迹不出圆 */
function circleScale() {
  return Math.min(1, (512 / inkRadius()) * 0.97);
}

/** 自适应前景：Android 安全区是中心 66dp / 108dp 画布 */
const SAFE_ZONE = { diameter: 66, canvas: 108 };

const PALETTES = {  indigo: {
    BG_A: '#2C3585', BG_B: '#1A1E58', INK: '#FFFFFF',
    BANANA_L: '#FFE9A6', BANANA_M: '#FFC93C', BANANA_R: '#EFA11B', BANANA_HL: '#FFF7DA',
    STEM: '#7FC77F', STEM_TIP: '#3C7845',
    LEAF: '#6CC46F', LEAF_MID: '#3E8F4C', LEAF_DARK: '#3E8F4C',
  },
  royal: {
    BG_A: '#4C86F5', BG_B: '#2B5FD9', INK: '#FFFFFF',
    BANANA_L: '#FFE9A6', BANANA_M: '#FFC93C', BANANA_R: '#EFA11B', BANANA_HL: '#FFF7DA',
    STEM: '#7FC77F', STEM_TIP: '#2F6B3A',
    LEAF: '#5CBE66', LEAF_MID: '#2F8443', LEAF_DARK: '#2F8443',
  },
  cream: {
    BG_A: '#FFF7E8', BG_B: '#F4E4C4', INK: '#33291F',
    BANANA_L: '#FFE07A', BANANA_M: '#FDBF2D', BANANA_R: '#E39414', BANANA_HL: '#FFF3C9',
    STEM: '#7FC77F', STEM_TIP: '#3C7845',
    LEAF: '#6CC46F', LEAF_MID: '#3E8F4C', LEAF_DARK: '#3E8F4C',
  },
  charcoal: {
    BG_A: '#33373F', BG_B: '#171A1F', INK: '#FFFFFF',
    BANANA_L: '#FFE9A6', BANANA_M: '#FFC93C', BANANA_R: '#EFA11B', BANANA_HL: '#FFF7DA',
    STEM: '#7FC77F', STEM_TIP: '#3C7845',
    LEAF: '#6CC46F', LEAF_MID: '#3E8F4C', LEAF_DARK: '#3E8F4C',
  },
  violet: {
    BG_A: '#7B78F5', BG_B: '#4B46C8', INK: '#FFFFFF',
    BANANA_L: '#FFE9A6', BANANA_M: '#FFC93C', BANANA_R: '#EFA11B', BANANA_HL: '#FFF7DA',
    STEM: '#7FC77F', STEM_TIP: '#3C7845',
    LEAF: '#6CC46F', LEAF_MID: '#3E8F4C', LEAF_DARK: '#3E8F4C',
  },
};

function findChrome() {
  for (const c of CHROME_CANDIDATES) if (fs.existsSync(c)) return c;
  throw new Error('未找到 Chrome / Edge，无法渲染 SVG');
}

let chrome = null;
const profileDir = path.join(os.tmpdir(), 'tiebanana-icon-chrome');

function svgFor(palette, shape) {
  const p = PALETTES[palette];
  if (!p) throw new Error('未知调色板: ' + palette);
  let svg = fs.readFileSync(SVG, 'utf8');
  for (const [k, v] of Object.entries(p)) svg = svg.split(`{{${k}}}`).join(v);
  svg = svg.split('{{BANANA_IMG}}').join(dataUri(path.join(__dirname, 'banana.png')));
  svg = svg.split('{{LEAF_IMG}}').join(dataUri(path.join(__dirname, 'leaf.png')));
  if (shape === 'stripped') {
    // 只留内容层（无背景），用来测量墨迹范围
    return svg.replace('<rect x="0" y="0" width="1024" height="1024" fill="url(#bg)"/>', '');
  }
  if (shape === 'circle' || shape === 'rounded') {
    const rx = shape === 'circle' ? 512 : 232;
    // 传统图标：把满幅背景换成圆角/圆形（iOS 与自适应前景保持满幅方形）
    svg = svg.replace(
      '<rect x="0" y="0" width="1024" height="1024" fill="url(#bg)"/>',
      `<rect x="0" y="0" width="1024" height="1024" rx="${rx}" ry="${rx}" fill="url(#bg)"/>`
    );
    if (shape === 'circle') {
      // 圆形会比方形裁掉角落，内容按实测墨迹半径缩放
      const k = circleScale();
      svg = svg.replace('<g transform="translate(',
        `<g transform="translate(512,512) scale(${k}) translate(-512,-512) translate(`);
    }
  }
  return svg;
}

function render(svg, size, outPng) {
  if (!chrome) chrome = findChrome();
  const tmp = path.join(os.tmpdir(), 'tiebanana-icon-render');
  fs.mkdirSync(tmp, { recursive: true });
  const svgFile = path.join(tmp, 'icon.svg');
  const htmlFile = path.join(tmp, 'page.html');
  fs.writeFileSync(svgFile, svg, 'utf8');
  fs.writeFileSync(htmlFile,
    `<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;background:transparent}img{display:block}</style>` +
    `<img src="icon.svg" width="${size}" height="${size}">`, 'utf8');
  fs.mkdirSync(path.dirname(outPng), { recursive: true });
  const args = [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run',
    '--no-default-browser-check', '--disable-extensions', '--disable-lcd-text',
    '--force-device-scale-factor=1', '--default-background-color=00000000',
    `--user-data-dir=${profileDir}`, `--window-size=${size},${size}`,
    `--screenshot=${outPng}`, 'file:///' + htmlFile.replace(/\\/g, '/'),
  ];
  const r = spawnSync(chrome, args, { stdio: 'ignore' });
  if (r.error) throw r.error;
  if (!fs.existsSync(outPng)) throw new Error('渲染失败: ' + outPng);
  return outPng;
}

function renderPalette(palette, size, outPng, shape) {
  return render(svgFor(palette, shape), size, outPng);
}

// ---- 输出各平台图标 ------------------------------------------------------
const ANDROID_MIPMAPS = { ldpi: 36, mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
// 自适应图标前景：108dp，内容缩到安全区（中心 66dp）内
const ANDROID_FOREGROUNDS = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };
const IOS_ICONS = [
  ['icon-20.png', 20], ['icon-20@2x.png', 40], ['icon-20@3x.png', 60],
  ['icon-29.png', 29], ['icon-29@2x.png', 58], ['icon-29@3x.png', 87],
  ['icon-40.png', 40], ['icon-40@2x.png', 80], ['icon-40@3x.png', 120],
  ['icon-60@2x.png', 120], ['icon-60@3x.png', 180],
  ['icon-76.png', 76], ['icon-76@2x.png', 152], ['icon-83.5@2x.png', 167],
  ['icon-1024.png', 1024],
  ['icon-20-ipad.png', 20], ['icon-20@2x-ipad.png', 40],
  ['icon-29-ipad.png', 29], ['icon-29@2x-ipad.png', 58],
];

function foregroundSvg(palette) {
  // 透明底 + 内容缩进 Android 安全区（中心 66dp），交给启动器的遮罩
  const safeScale = Math.min(1, ((512 * SAFE_ZONE.diameter / SAFE_ZONE.canvas) / inkRadius()) * 0.97);
  let svg = svgFor(palette, 'none');
  svg = svg.replace('<rect x="0" y="0" width="1024" height="1024" fill="url(#bg)"/>', '');
  svg = svg.replace('<g transform="translate(',
    `<g transform="translate(512,512) scale(${safeScale}) translate(-512,-512) translate(`);
  return svg;
}

function build(palette) {
  const out = [];
  // Android 传统 mipmap（圆角方形 + 圆形）
  for (const [dpi, size] of Object.entries(ANDROID_MIPMAPS)) {
    const dir = path.join(ROOT, 'android', 'app', 'src', 'main', 'res', `mipmap-${dpi}`);
    out.push(renderPalette(palette, size, path.join(dir, 'ic_launcher.png'), 'rounded'));
    out.push(renderPalette(palette, size, path.join(dir, 'ic_launcher_round.png'), 'circle'));
  }
  // Android 自适应图标前景（各密度 108dp）
  for (const [dpi, size] of Object.entries(ANDROID_FOREGROUNDS)) {
    const dir = path.join(ROOT, 'android', 'app', 'src', 'main', 'res', `drawable-${dpi}`);
    out.push(render(foregroundSvg(palette), size, path.join(dir, 'ic_launcher_foreground.png')));
  }
  // iOS：满幅方形，无圆角
  const iosDir = path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
  for (const [name, size] of IOS_ICONS) {
    out.push(renderPalette(palette, size, path.join(iosDir, name), 'none'));
  }
  // 仓库内 1024 源图
  out.push(renderPalette(palette, 1024, path.join(ROOT, 'assets', 'icon', 'ic_launcher_round.png'), 'circle'));
  out.push(renderPalette(palette, 1024, path.join(ROOT, 'assets', 'icon', 'ic_launcher.png'), 'none'));
  return out;
}

function preview() {
  fs.mkdirSync(WIP, { recursive: true });
  const names = Object.keys(PALETTES);
  for (const n of names) renderPalette(n, 1024, path.join(WIP, `vector_${n}.png`), 'none');
  const cards = names.map((n) => `
    <div class="card">
      <img class="big" src="vector_${n}.png">
      <div class="meta"><span class="name">${n}</span>
        <span class="tiny"><img class="t48" src="vector_${n}.png"><img class="t24" src="vector_${n}.png"></span>
      </div>
    </div>`).join('');
  const html = `<!doctype html><meta charset="utf-8"><style>
    body{margin:0;padding:26px 30px;background:#14161c;color:#e8eaf0;font-family:"Microsoft YaHei UI","Segoe UI",sans-serif}
    h1{font-size:24px;margin:0 0 20px}
    .grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}
    .card{background:#1c1f28;border:1px solid #272b36;border-radius:14px;padding:12px;display:flex;flex-direction:column;gap:10px}
    img.big{width:100%;aspect-ratio:1/1;display:block;border-radius:22%}
    .meta{display:flex;align-items:center;gap:10px}
    .name{font-size:12.5px;color:#b9c1d4}
    .tiny{margin-left:auto;display:flex;gap:8px}
    .t48{width:48px;height:48px;border-radius:11px}.t24{width:24px;height:24px;border-radius:6px}
    .row{display:flex;gap:16px;margin-top:20px;align-items:center;background:#1c1f28;border:1px solid #272b36;border-radius:14px;padding:14px}
    .row img{display:block}
    .lbl{font-size:12.5px;color:#8b93a7;width:110px}
  </style>
  <h1>Tiebanana 矢量图标 · 调色板对比</h1>
  <div class="grid">${cards}</div>
  <div class="row"><span class="lbl">indigo 小尺寸</span>
    ${[96, 72, 48, 36, 24].map((s) => `<img src="vector_indigo.png" width="${s}" height="${s}">`).join('')}
  </div>`;
  fs.writeFileSync(path.join(WIP, 'vector_contact.html'), html, 'utf8');
  return path.join(WIP, 'vector_contact.html');
}

function ladder(palette) {
  fs.mkdirSync(WIP, { recursive: true });
  const sizes = [192, 144, 96, 72, 48, 36, 24];
  const files = [];
  for (const s of sizes) {
    const f = path.join(WIP, `ladder_${palette}_${s}.png`);
    renderPalette(palette, s, f, 'rounded');
    const c = path.join(WIP, `ladder_${palette}_c${s}.png`);
    renderPalette(palette, s, c, 'circle');
    files.push([s, `ladder_${palette}_${s}.png`, `ladder_${palette}_c${s}.png`]);
  }
  const html = `<!doctype html><meta charset="utf-8"><style>
    body{margin:0;padding:24px 28px;background:#e9ebf0;color:#23262e;font-family:"Microsoft YaHei UI","Segoe UI",sans-serif}
    h1{font-size:22px;margin:0 0 18px}
    .row{display:flex;align-items:flex-end;gap:26px;margin-bottom:24px}
    .cell{display:flex;flex-direction:column;align-items:center;gap:8px}
    .cap{font-size:12px;color:#5b6172}
    .dark{background:#14161c;padding:20px;border-radius:12px;display:flex;align-items:flex-end;gap:26px}
    .dark .cap{color:#98a0b4}
    img{display:block}
  </style>
  <h1>Tiebanana 图标 · 真实尺寸阶梯（${palette}，圆角 / 圆形）</h1>
  <div class="row">${files.map(([s, a, b]) => `<div class="cell"><img src="${a}"><img src="${b}"><span class="cap">${s}px</span></div>`).join('')}</div>
  <div class="dark">${files.map(([s, a, b]) => `<div class="cell"><img src="${a}"><img src="${b}"><span class="cap">${s}px</span></div>`).join('')}</div>`;
  const htmlFile = path.join(WIP, `ladder_${palette}.html`);
  fs.writeFileSync(htmlFile, html, 'utf8');
  return htmlFile;
}

const [cmd, arg] = process.argv.slice(2);
if (cmd === 'preview') {
  const html = preview();
  console.log('preview ->', html);
} else if (cmd === 'ladder') {
  const p = arg || 'indigo';
  const html = ladder(p);
  console.log('ladder ->', html);
} else if (cmd === 'build') {
  const k = circleScale();
  console.log(`墨迹半径 ${inkRadius().toFixed(1)}px / 1024，圆形缩放 ${k.toFixed(3)}，安全区缩放 ${(
    (512 * SAFE_ZONE.diameter / SAFE_ZONE.canvas / inkRadius()) * 0.97).toFixed(3)}`);
  const files = build(arg || 'indigo');
  console.log(`已输出 ${files.length} 个图标文件（palette=${arg || 'indigo'}）`);
} else {
  console.log('用法: node docs/icon/build_icons.js preview | ladder <palette> | build <palette>');
  console.log('调色板:', Object.keys(PALETTES).join(', '));
}
