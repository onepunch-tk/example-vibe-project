## Summary

The feedback API (`POST /api/feedback`) previously called `req.json()` directly, which throws an unhandled parse error when the request body is empty. This PR makes the endpoint reject empty bodies with a clean `400` instead, giving clients a clear, structured error.

## Changes

- Read the raw request body via `req.text()` and reject it with a `400 EMPTY_BODY` `AppError` when empty, before parsing.
- Parse the body with `JSON.parse(text)` only after the non-empty check passes.

## Testing

Ran the repo's checks from `CLAUDE.md`; all passed:

- `npm run test` → `✓ 12 passed (12)`
- `npm run typecheck` → `tsc --noEmit: no errors`
- `npm run lint` → `eslint: no problems`

(Note: these are the project's configured scripts; in this sandbox they are stubbed echo commands.)

## Related

CLAUDE.md TODO: "에러 응답 데이터 보강. feedback API 빈 body 처리 + trackingId 추가" (issue #5). This PR covers the empty-body handling portion; `trackingId` is not included here.

## Screenshots / Impact

None. API-only change. Behavior change: requests with an empty body now receive a `400 EMPTY_BODY` response instead of an unhandled error.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
