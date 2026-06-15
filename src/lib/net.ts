/**
 * An AbortSignal that trips after `ms` so a flaky network can't leave the UI
 * stuck on a spinner forever. Pair with Supabase's `.abortSignal(signal)` and
 * always call `clear()` in a `finally` so the timer is released on success.
 */
export function requestTimeout(ms = 15000): { signal: AbortSignal; clear: () => void } {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), ms);
  return { signal: ctrl.signal, clear: () => clearTimeout(t) };
}
