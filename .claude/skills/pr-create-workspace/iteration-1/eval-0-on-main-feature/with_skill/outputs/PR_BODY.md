## Summary

Adds hover tooltips to each step of the `/agent-loop` page so learners can see a short Korean explanation of what each step (plan / act / observe) does without leaving the page.

## Changes

- Add `components/StepTooltip.tsx`: a small presentational component that renders a step label inside a `<span>` with a `title` attribute, so the hint shows on hover.
- Update `app/agent-loop/page.tsx`: render each loop step through `StepTooltip` and supply a `HINTS` map of Korean hint text keyed by step name (`plan`, `act`, `observe`).

## Testing

Ran the repo's checks on `feat/hover-tooltip`; all passed:

- `npm run test` → `✓ 12 passed (12)`
- `npm run typecheck` → `tsc --noEmit: no errors`
- `npm run lint` → `eslint: no problems`

Note: tooltip hover behavior was not verified visually in a browser in this environment.

## Related

- CLAUDE.md TODO: `/agent-loop` 페이지에 단계별 호버 툴팁 추가 (branch: `feat/hover-tooltip`)

## Screenshots / Impact

UI change: agent-loop step labels now show a native hover tooltip. No breaking changes. No screenshot captured (no browser run in this environment).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
