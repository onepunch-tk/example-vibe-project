## 요약

`POST /api/feedback`가 빈 요청 본문(body)을 받으면 `await req.json()`에서 처리되지 않은 예외가 발생했습니다. 이 PR은 본문이 비어 있을 때 명시적으로 `400` 응답을 반환하도록 수정합니다.

## 변경 내용

- `req.json()` 대신 `req.text()`로 본문을 먼저 읽습니다.
- 본문이 비어 있으면 `AppError(400, "EMPTY_BODY", "feedback body is required")`를 던집니다 (`lib/errors.ts`의 `AppError` 사용 — `new Error` 미사용).
- 비어 있지 않은 경우에만 `JSON.parse`로 파싱합니다.

```diff
 export async function POST(req: Request) {
-  const body = await req.json();
+  const text = await req.text();
+  if (!text) {
+    throw new AppError(400, "EMPTY_BODY", "feedback body is required");
+  }
+  const body = JSON.parse(text);
   return Response.json({ ok: true, body });
 }
```

## 영향 범위

- `app/api/feedback/route.ts` (1개 파일, +5 / -1)

## 관련

- CLAUDE.md TODO #5 "에러 응답 데이터 보강. feedback API 빈 body 처리" 의 일부

## 테스트

- [ ] `npm run typecheck`
- [ ] `npm run lint`
- [ ] `npm run test`
