const prefix = 'codex-theme-v1:';
export function paletteFromImport(source) {
  if (!source.startsWith(prefix)) throw new Error('Invalid import');
  const {theme} = JSON.parse(source.slice(prefix.length));
  return {background: theme.surface, foreground: theme.ink, accent: theme.accent};
}
export function customizeImport(source, colors) {
  validateColors(colors);
  const initial = paletteFromImport(source);
  if (Object.keys(initial).every(key => initial[key] === colors[key])) return source;
  const payload = JSON.parse(source.slice(prefix.length));
  payload.theme.surface = colors.background;
  payload.theme.ink = colors.foreground;
  payload.theme.accent = colors.accent;
  return prefix + JSON.stringify(payload);
}
const xml = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
export function normalizeTheme(meta, source) {
  const palette = paletteFromImport(source);
  if (!meta || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(meta.slug) || !['dark','light'].includes(meta.mode) || typeof meta.name !== 'string' || !meta.name.trim() || typeof meta.author !== 'string' || !meta.author.trim()) throw new Error('Invalid theme metadata');
  validateColors(palette);
  const payload = JSON.parse(source.slice(prefix.length));
  if (payload.variant !== meta.mode || !payload.theme || typeof payload.codeThemeId !== 'string') throw new Error('Invalid desktop payload');
  const semantic = payload.theme.semanticColors ?? {};
  if (!semantic || typeof semantic !== 'object' || Array.isArray(semantic)) throw new Error('Invalid semantic colors');
  for (const [key, value] of Object.entries(semantic)) if (!['diffAdded','diffRemoved','skill'].includes(key) || typeof value !== 'string' || !/^#[0-9a-fA-F]{6}$/.test(value)) throw new Error('Invalid semantic color');
  const {surface,ink,accent,semanticColors,...overrides} = payload.theme;
  return {id:meta.slug,name:meta.name,author:meta.author,mode:meta.mode,shared:{...palette,semantic},desktop:{source,overrides},cli:{overrides:{}}};
}
export function validateColors(colors) {
  for (const key of ['background','foreground','accent']) if (!/^#[0-9a-fA-F]{6}$/.test(colors[key])) throw new Error(`Invalid ${key}`);
}
export function exportTmTheme(name, colors) {
  validateColors(colors);
  if (typeof name !== 'string' || [...name].some(c => { const n = c.codePointAt(0); return !(n === 9 || n === 10 || n === 13 || (n >= 0x20 && n <= 0xd7ff) || (n >= 0xe000 && n <= 0xfffd) || (n >= 0x10000 && n <= 0x10ffff)); })) throw new Error('Invalid name');
  return `<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict><key>name</key><string>${xml(name)}</string><key>settings</key><array><dict><key>settings</key><dict><key>background</key><string>${colors.background}</string><key>foreground</key><string>${colors.foreground}</string><key>caret</key><string>${colors.accent}</string><key>selection</key><string>${colors.accent}</string></dict></dict></array></dict></plist>\n`;
}
