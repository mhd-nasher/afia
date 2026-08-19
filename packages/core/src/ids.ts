let counter = 0

/** Unique id; crypto.randomUUID when available, deterministic fallback in tests. */
export function newId(prefix: string): string {
  const c = globalThis.crypto
  if (c && typeof c.randomUUID === 'function') return `${prefix}_${c.randomUUID()}`
  counter += 1
  return `${prefix}_${Date.now().toString(36)}_${counter}`
}
