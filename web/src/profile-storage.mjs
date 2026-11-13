import { importProfile } from './serializer.mjs';

const KEY = 'morph-profiles';
export function readProfiles(storage = localStorage) {
  try {
    const value = JSON.parse(storage.getItem(KEY) || '[]');
    if (!Array.isArray(value)) return [];
    return value.filter(item => {
      try { importProfile(JSON.stringify(item)); return typeof item.id === 'string'; }
      catch { return false; }
    });
  } catch { return []; }
}
export function writeProfiles(profiles, storage = localStorage) {
  storage.setItem(KEY, JSON.stringify(profiles));
}
