#!/usr/bin/env bash
# Stop hook: 기능 브랜치에 base보다 앞선 커밋이 있고 아직 PR이 없으면,
# Claude 에게 pr-flow 스킬로 draft PR 생성을 지시(decision:block)한다. 브랜치당 1회.
# set -e 는 일부러 빼서 비매칭/실패 종료코드가 흐름을 끊지 않게 한다.
set -uo pipefail

input=$(cat)

# 무한 루프 방지: stop hook 으로 인한 연속 실행이면 통과
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0
command -v gh >/dev/null 2>&1 || exit 0   # gh 없으면 조용히 통과

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
case "$branch" in ""|main|master) exit 0 ;; esac

# base 브랜치 결정 (origin/HEAD → 기본 main)
base=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$base" ] && base="main"

# base 대비 앞선 커밋이 없으면 통과 (아직 커밋된 작업 없음)
ahead=$(git rev-list --count "origin/${base}..HEAD" 2>/dev/null \
        || git rev-list --count "${base}..HEAD" 2>/dev/null || echo 0)
{ [ "${ahead:-0}" -gt 0 ]; } 2>/dev/null || exit 0

# 이미 이 브랜치로 PR 이 있으면 통과 (브랜치당 1회만 발동)
gh pr view "$branch" --json state >/dev/null 2>&1 && exit 0

# 조건 충족 → Claude 에게 pr-flow 스킬로 draft PR 생성 지시
reason="기능 브랜치 '${branch}'에 base(${base}) 대비 ${ahead}개 커밋이 있고 아직 PR이 없습니다. pr-flow 스킬을 사용해 남은 변경을 커밋·push하고 draft PR(gh pr create --draft)을 생성하세요."
printf '{"decision":"block","reason":%s}\n' "$(printf '%s' "$reason" | jq -Rs .)"
exit 0
