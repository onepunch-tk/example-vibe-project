# CLAUDE.md — Claude Code 핵심개념 한국어 학습자를 위한 시각자료


마지막 업데이트: 2026-05-24

---

## 1. 절대 규칙 (3~5개)

- 절대 `console.log`를 production 코드에 두지 말 것. `logger.ts` 사용.
- 절대 `process.env`를 직접 읽지 마라. `config/env.ts`를 통해서만.
- 절대 `main` or `master` branch에 직접 커밋하지 말 것.
- 불필요한 모듈화로 인한 오버엔지니어링을 피해라. 하나의 파일에서만 사용하는 const/var/function을 파일로 따로 분리하여 모듈화하는 오버엔지니어링은 피할 것.
- 절대 에러 처리시 `new Error` 메써드를 사용하지 말 것. `errors.ts` 사용.

> 절대 규칙 = 위반 시 PR 거부될 만한 것만. 3~5개를 넘으면 "절대"가 아닙니다.

---

## 2. 명령어 치트시트

```bash
npm run dev                  # 개발 서버 시작
npm run build                # 프로젝트 빌드

# 테스트
npm run test                 # 전체
npm run test:watch           # watch 모드
npm run test path/to/file    # 단일 파일

# Lint / 타입체크
npm run lint                 # linting
npm run typecheck            # typescript typecheck
npm run format               # prettier formatting
```

---

## 3. 아키텍처 한눈에

```
app/         # Next.js App Router — 페이지 + API 라우트(app/api/)
components/  # 재사용 React 컴포넌트 (시각화 + 클라이언트 폼)
lib/         # 도메인 로직 (concepts 데이터, API 클라이언트, 공통 유틸)
tests/       # vitest 테스트 (src 밖, 여기에만 위치)
```

**핵심 모듈 3~5개**:
- `lib/concepts.ts` — 개념 데이터 진입점. `lib/data/concepts.json`을 읽어 `listConcepts()`/`findConcept(slug)` 제공.
- `lib/api/` — 클라이언트→API 호출 래퍼. `fetch-client.ts`(개념 조회), `axios-client.ts`(피드백 전송).
- `lib/logger.ts` — 구조화 JSON 로거. `console.*` 직접 호출 대신 `logger.info/warn/error`만 사용.
- `lib/errors.ts` — `AppError`(status·code 포함). API 라우트 에러 응답의 단일 출처.
- `app/api/` — 라우트 핸들러. `concepts/`(GET·`[slug]`), `feedback/`(POST, 학습자 미완성 stub).

---

## 4. 컨벤션

### 네이밍
- 파일: `kebab-case.ts`
- 컴포넌트: `PascalCase.tsx`
- hook: `useXxx.ts`
- 테스트: `<원본>.test.ts`

### 코드
- 일반 함수: `exoort const a = () => {}`
- react component: `export defualt funtion A() { return <>...<> }`
- type: 가급적 `interface`보다 `type` 먼저 사용.

### 테스트
- 단위 테스트는 mocking OK
- 통합 테스트는 실제 DB (sqlite in-memory) — mocking 금지
- 모든 테스트는 `tests/` 아래, 절대 `src/` 안에 두지 않음

### 에러 처리
- API 라우트는 `lib/errors.ts`의 `AppError` 던지기
- catch 블록에서 무의미한 `console.log` 금지 — `logger.error`만

### 데이터 페칭
- `lib/api/fetch-client.ts` `fetchConcepts` 사용

---

## 5. 지금 진행 중 (TODO)

- [ ] `/agent-loop` 페이지에 단계별 호버 툴팁 추가 
  - branch: `feat/hover-tooltip`
  - 참조: `@IDEAS.md` #1 섹션
- [ ] 에러 응답 데이터 보강. `trackingId` 추가
  - branch: `feat/error-response-data`
  - 참조: `@IDEAS.md` #5 섹션

---

