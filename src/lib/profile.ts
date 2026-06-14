import AsyncStorage from "@react-native-async-storage/async-storage";

const KEY = "gauss.profile_id";
let cached: string | null = null;

function uuid(): string {
  // RFC4122-ish v4 without external deps.
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/** Stable per-install id for a single-user personal app (no login). */
export async function getProfileId(): Promise<string> {
  if (cached) return cached;
  let id = await AsyncStorage.getItem(KEY);
  if (!id) {
    id = uuid();
    await AsyncStorage.setItem(KEY, id);
  }
  cached = id;
  return id;
}
