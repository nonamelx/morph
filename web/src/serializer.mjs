import Ajv from 'ajv';
import profileSchema from './profile-v1.schema.json' with { type: 'json' };
const profileValidator = new Ajv().compile(profileSchema);
const prefix = 'codex-theme-v1:';
export function paletteFromImport(source) {
  if (!source.startsWith(prefix)) throw new Error('Invalid import');
  const {theme} = JSON.parse(source.slice(prefix.length));
  return {background: theme.surface, foreground: theme.ink, accent: theme.accent};
}
export function customizeImport(source, colors) {
  validateColors(colors);
  const initial = paletteFromImport(source);
  const payload = JSON.parse(source.slice(prefix.length));
  const semantic = payload.theme.semanticColors ?? {};
  if (Object.keys(initial).every(key => initial[key] === colors[key]) && ['diffAdded','diffRemoved','skill'].every(key => !colors[key] || colors[key] === semantic[key])) return source;
  payload.theme.surface = colors.background;
  payload.theme.ink = colors.foreground;
  payload.theme.accent = colors.accent;
  payload.theme.semanticColors ??= {};
  for (const key of ['diffAdded','diffRemoved','skill']) if (colors[key]) payload.theme.semanticColors[key] = colors[key];
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
  for (const key of ['background','foreground','accent','keyword','string','number','diffAdded','diffRemoved']) if (colors[key] !== undefined && !/^#[0-9a-fA-F]{6}$/.test(colors[key])) throw new Error(`Invalid ${key}`);
  for (const key of ['background','foreground','accent']) if (!/^#[0-9a-fA-F]{6}$/.test(colors[key])) throw new Error(`Invalid ${key}`);
}
const validXmlName = name => typeof name === 'string' && [...name].every(c => { const n = c.codePointAt(0); return n === 9 || n === 10 || n === 13 || (n >= 0x20 && n <= 0xd7ff) || (n >= 0xe000 && n <= 0xfffd) || (n >= 0x10000 && n <= 0x10ffff); });
export function exportTmTheme(name, colors) {
  validateColors(colors);
  if (!validXmlName(name)) throw new Error('Invalid name');
  const scopes = [['keyword, storage, entity.name.function','keyword'],['string','string'],['constant.numeric, constant.language','number'],['diff.inserted, markup.inserted','diffAdded'],['diff.deleted, markup.deleted','diffRemoved']];
  const rules = scopes.filter(([,key])=>colors[key]).map(([scope,key])=>`<dict><key>scope</key><string>${scope}</string><key>settings</key><dict><key>foreground</key><string>${colors[key]}</string></dict></dict>`).join('') || `<dict><key>scope</key><string>keyword, storage, constant, entity.name.function</string><key>settings</key><dict><key>foreground</key><string>${colors.accent}</string></dict></dict>`;
  return `<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict><key>name</key><string>${xml(name)}</string><key>settings</key><array><dict><key>settings</key><dict><key>background</key><string>${colors.background}</string><key>foreground</key><string>${colors.foreground}</string><key>caret</key><string>${colors.accent}</string><key>selection</key><string>${colors.accent}</string></dict></dict>${rules}</array></dict></plist>\n`;
}

export const PROFILE_SCHEMA_VERSION = 1;
export function validateProfile(profile) {
  if (!profileValidator(profile) || !validXmlName(profile.name)) throw new Error('Invalid Morph profile');
  validateColors(profile.colors);
  return profile;
}
export function exportProfile(profile) { validateProfile(profile); return JSON.stringify(profile,null,2); }
export function importProfile(text) { let profile; try { profile=JSON.parse(text); } catch { throw new Error('Profile must be valid JSON'); } return validateProfile(profile); }
export function createHistory(initial) {
  let past=[], present=structuredClone(initial), future=[];
  return { get present(){return present}, get canUndo(){return past.length>0}, get canRedo(){return future.length>0}, push(value){past.push(present);present=structuredClone(value);future=[]}, undo(){if(past.length){future.unshift(present);present=past.pop()}return present}, redo(){if(future.length){past.push(present);present=future.shift()}return present}, reset(value){past.push(present);present=structuredClone(value);future=[]} };
}

export function resolveProfileBase(profile, themes) {
  const base = themes.find(theme => theme.slug === profile.baseTheme);
  if (!base || base.mode !== profile.mode) throw new Error('Profile base theme is missing, unknown, or has a different mode');
  return base;
}
