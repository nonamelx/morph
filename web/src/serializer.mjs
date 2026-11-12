export function customizeImport(source, colors) {
  const prefix = 'codex-theme-v1:';
  if (!source.startsWith(prefix)) throw new Error('Invalid import');
  const payload = JSON.parse(source.slice(prefix.length));
  payload.theme.surface = colors.background;
  payload.theme.ink = colors.foreground;
  payload.theme.accent = colors.accent;
  return prefix + JSON.stringify(payload);
}
