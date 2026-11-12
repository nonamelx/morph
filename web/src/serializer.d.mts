export type Colors = {background: string; foreground: string; accent: string};
export function paletteFromImport(source: string): Colors;
export function customizeImport(source: string, colors: Colors): string;
export function normalizeTheme(meta: {slug:string;name:string;author:string;mode:string}, source:string): {id:string;name:string;author:string;mode:string;shared:Colors & {semantic:Record<string,string>};desktop:{source:string;overrides:Record<string,unknown>};cli:{overrides:Record<string,never>}};
export function validateColors(colors: Colors): void;
export function exportTmTheme(name:string, colors:Colors): string;
export function validateProfile(profile: unknown): any;
export function exportProfile(profile: unknown): string;
export function importProfile(text: string): any;
export function createHistory<T>(initial: T): {present:T;canUndo:boolean;canRedo:boolean;push(value:T):void;undo():T;redo():T;reset(value:T):void};

export function resolveProfileBase<T extends {slug:string;mode:string}>(profile: any, themes:T[]):T;
