#!/usr/bin/env bash
# PreToolUse(Bash) guard: main/master 직접 git commit 차단 (CLAUDE.md 절대 규칙 #3)
#
# stdin 으로 { "tool_input": { "command": "..." } } JSON 을 받아,
# 명령이 git commit 이고 현재 브랜치가 main/master 이면 deny 한다.
# set -e 는 일부러 빼서 grep/jq 비매칭 종료코드가 흐름을 끊지 않게 한다.
set -uo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# git commit 서브커맨드 판별 (전역 옵션 -c/-C/--flag 허용). 아니면 통과.
if ! printf '%s' "$command" | grep -Eq 'git( +-[^ ]+| +--[^ ]+(=[^ ]*)?| +-c +[^ ]+| +-C +[^ ]+)* +commit( |$)'; then
  exit 0
fi

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [[ "$branch" == "main" || "$branch" == "master" ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"현재 '$branch' 브랜치입니다. CLAUDE.md 절대 규칙: main/master 직접 커밋 금지. feature 브랜치를 생성한 뒤 커밋하세요."}}
EOF
fi

exit 0
