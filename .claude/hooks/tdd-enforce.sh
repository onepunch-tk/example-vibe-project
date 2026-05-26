#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit) guard: TDD 강제.
# lib/ · components/ 아래 .ts/.tsx 소스를 작성/수정하려 할 때
# 대응 테스트(tests/<basename>.test.ts[x])가 없으면 deny 하고,
# 메인 에이전트에게 tdd-red-phase-writer 서브에이전트 호출을 지시한다.
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0

# 선언 파일 제외
case "$file" in
  *.d.ts) exit 0 ;;
esac

# lib/ · components/ 아래 .ts/.tsx 만 대상 (그 외 전부 통과)
case "$file" in
  */lib/*.ts|*/lib/*.tsx|*/components/*.ts|*/components/*.tsx) ;;
  lib/*.ts|lib/*.tsx|components/*.ts|components/*.tsx) ;;
  *) exit 0 ;;
esac

# 테스트 파일 자체는 통과 (방어적)
case "$file" in
  *.test.ts|*.test.tsx) exit 0 ;;
esac

# basename 에서 확장자 제거 → 대응 테스트 후보
base=$(basename "$file")
base="${base%.*}"

found=$(find "$CLAUDE_PROJECT_DIR/tests" -type f \
  \( -name "${base}.test.ts" -o -name "${base}.test.tsx" \) 2>/dev/null | head -n1)
[ -n "$found" ] && exit 0

# 테스트 없음 → 차단 + tdd-red-phase-writer 호출 지시
reason="TDD 강제: '${file}' 의 대응 테스트(tests/${base}.test.ts)가 없습니다. 구현 코드를 먼저 작성할 수 없습니다. 먼저 Agent 도구로 tdd-red-phase-writer 서브에이전트를 호출해 tests/${base}.test.ts 에 실패하는 테스트를 작성한 뒤, 이 파일 작성을 다시 시도하세요."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
  "$(printf '%s' "$reason" | jq -Rs .)"
exit 0
