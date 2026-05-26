## 개요

`/agent-loop` 페이지의 각 단계(plan / act / observe)에 호버 시 설명을 보여주는 툴팁을 추가했습니다. CLAUDE.md TODO 항목 "`/agent-loop` 페이지에 단계별 호버 툴팁 추가"에 해당합니다.

## 변경 사항

- `components/StepTooltip.tsx` 신규 추가 — `label`과 `hint`를 받아 `title` 속성으로 호버 툴팁을 렌더링하는 컴포넌트.
- `app/agent-loop/page.tsx` — 각 단계 리스트 항목을 `StepTooltip`으로 렌더링하도록 변경하고, 단계별 한국어 설명(`HINTS`)을 추가.

## 동작

각 단계 라벨에 마우스를 올리면 다음 설명이 표시됩니다.

- plan: 다음 행동을 계획합니다
- act: 도구를 호출합니다
- observe: 결과를 관찰합니다

## 테스트

- `npm run lint` — 통과
- `npm run typecheck` — 통과
- `npm run test` — 통과

🤖 Generated with [Claude Code](https://claude.com/claude-code)
