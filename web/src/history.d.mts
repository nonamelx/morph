export function saveSnapshot<T>(history: {palette:T;name:string}[], palette:T, name:string): {palette:T;name:string}[];
export function undoSnapshot<T>(history: {palette:T;name:string}[]): {snapshot:{palette:T;name:string};history:{palette:T;name:string}[]} | null;
