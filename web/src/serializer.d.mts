export type Colors = {background: string; foreground: string; accent: string};
export function paletteFromImport(source: string): Colors;
export function customizeImport(source: string, colors: Colors): string;
