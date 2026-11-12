const prefix = 'codex-theme-v1:';
export function paletteFromImport(source) {
  if (!source.startsWith(prefix)) throw new Error('Invalid import');
  const {theme} = JSON.parse(source.slice(prefix.length));
  return {background: theme.surface, foreground: theme.ink, accent: theme.accent};
}
export function customizeImport(source, colors) {
  const initial = paletteFromImport(source);
  if (Object.keys(initial).every(key => initial[key] === colors[key])) return source;
  const payload = JSON.parse(source.slice(prefix.length));
  payload.theme.surface = colors.background;
  payload.theme.ink = colors.foreground;
  payload.theme.accent = colors.accent;
  return prefix + JSON.stringify(payload);
}
