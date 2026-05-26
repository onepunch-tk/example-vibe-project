## Summary

The `POST /api/feedback` route called `req.json()` directly, which throws when the
request body is empty — surfacing as an unhandled 500. This change validates the
body first and returns a proper 400 instead.

## Changes

- Read the raw request body with `req.text()` before parsing.
- Throw `AppError(400, "EMPTY_BODY", ...)` when the body is empty, so an empty
  request now yields a 400 client error instead of a 500.
- Parse the validated text with `JSON.parse` to build the response.

## Testing

- `npm run test` — ✓ 12 passed (12)
- `npm run typecheck` — tsc --noEmit: no errors
- `npm run lint` — eslint: no problems

## Related

- Closes #5
- CLAUDE.md TODO §5: "에러 응답 데이터 보강. feedback API 빈 body 처리 + trackingId 추가"
  (this PR covers the empty-body handling portion)

## Screenshots / Impact

None. Behavior change only: an empty feedback request body now returns 400
(`EMPTY_BODY`) instead of an unhandled 500. No breaking changes to valid requests.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
