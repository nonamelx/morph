export function saveSnapshot(history, palette, name) { return [...history, {palette, name}]; }
export function undoSnapshot(history) { return history.length ? {snapshot: history[history.length - 1], history: history.slice(0, -1)} : null; }
