import { defineConfig } from 'vitest/config'

// Live-integration tests against the real Firebase project. Run explicitly:
//   npx vitest run --config vitest.live.config.ts
// Excluded from `npm test` (unit suite must stay offline-deterministic).
export default defineConfig({
  test: {
    include: ['packages/**/*.livetest.ts'],
    environment: 'node',
    testTimeout: 45_000,
    hookTimeout: 45_000,
  },
})
