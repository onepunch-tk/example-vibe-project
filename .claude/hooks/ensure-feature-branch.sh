#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit) guard: main/master 에서 소스 편집 차단.
# 이미 기능 브랜치(feat/ fix/ ... prefix)면 즉시 통과한다.
# main/master 면 deny 하고, pr-flow 스킬로 기능 브랜치를 만든 뒤 재시도하도록 지시한다.
# set -e 는 일부러 빼서 비매칭 종료코드가 흐름을 끊지 않게 한다.
set -uo pipefail

cat >/dev/null   # stdin 소비 (내용 불필요)

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# 이미 기능 브랜치 → 통과 (매번 호출돼도 여기서 빠르게 종료)
case "$branch" in
  feat/*|fix/*|hotfix/*|docs/*|chore/*|refactor/*|test/*|perf/*|style/*|build/*|ci/*|revert/*)
    exit 0 ;;
esac

# main/master 가 아닌 다른 브랜치는 막지 않음
case "$branch" in
  main|master) ;;
  *) exit 0 ;;
esac

# main/master → deny + pr-flow 스킬로 브랜치 생성 지시
reason="현재 '${branch}' 브랜치입니다. 소스 편집 전에 기능 브랜치가 필요합니다. pr-flow 스킬을 사용해 작업 내용에 맞는 기능 브랜치(feat/…, fix/… 등)를 생성·이동한 뒤 이 편집을 다시 시도하세요."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
  "$(printf '%s' "$reason" | jq -Rs .)"
exit 0
