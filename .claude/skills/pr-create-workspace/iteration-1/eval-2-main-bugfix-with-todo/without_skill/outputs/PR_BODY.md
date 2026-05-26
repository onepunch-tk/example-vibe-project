## 요약

`POST /api/feedback`에 빈 body가 들어오면 500이 나던 문제를 수정했습니다.

기존 코드는 `await req.json()`을 바로 호출했는데, body가 비어 있으면 JSON 파싱이 예외를 던지고 이게 처리되지 않은 채 500으로 노출됐습니다. 이제 raw text를 먼저 읽어 비어 있으면 `AppError(400, "EMPTY_BODY")`를 던지고, 그 외에는 정상적으로 파싱합니다.

## 변경 내용

- `app/api/feedback/route.ts`
  - `req.text()`로 본문을 먼저 읽고, 비어 있으면 `AppError(400, "EMPTY_BODY", "feedback body is required")`를 던짐
  - 본문이 있을 때만 `JSON.parse`로 파싱
- `CLAUDE.md`
  - TODO #5 항목에서 "feedback API 빈 body 처리" 체크 완료 표시

## 동작 변화

| 입력 | 변경 전 | 변경 후 |
| --- | --- | --- |
| 빈 body | 500 (unhandled) | 400 `EMPTY_BODY` |
| 정상 JSON body | 200 | 200 (동일) |

## 검증

- `npm run typecheck` 통과
- `npm run lint` 통과
- `npm run test` 통과

## 남은 작업

- 이슈 #5의 `trackingId` 추가는 이 PR 범위 밖이며 후속으로 진행 예정입니다 (CLAUDE.md TODO에 미완료로 남겨둠).

Refs #5

🤖 Generated with [Claude Code](https://claude.com/claude-code)
