---
name: project-test-infra
description: Test runner, tooling, and conventions for this project (example-vibe-project)
metadata:
  type: project
---

Test runner: **vitest 3** (`npm run test` → `vitest run`). `globals: true`, `environment: "jsdom"`.

React testing: `@testing-library/react` 16, React 19. Uses `render`, `screen`, `fireEvent` from `@testing-library/react`. No `@testing-library/user-event` in devDependencies.

Import alias: `@` maps to repo root (e.g. `import { LoopDiagram } from "@/components/LoopDiagram"`).

Test file conventions (from `tests/concepts.test.ts`):
- Named imports from vitest: `import { describe, it, expect } from "vitest"`
- Tests live under `tests/` only, named `<original>.test.ts`
- `it()` descriptions in Korean
- No beforeEach/afterEach setup patterns observed in sampled files

React component test note: React components must be called via `render(LoopDiagram())` (direct call, not JSX) since `.test.ts` extension is used (not `.test.tsx`). This works because React 19 returns JSX directly.

**Why:** Project uses `tests/` for all tests, never `src/`. Hook (`ensure-feature-branch`) enforces exact file path patterns.
**How to apply:** Always place test files at `tests/<ComponentName>.test.ts` and use `render(Component())` pattern (not JSX) for `.test.ts` files.
