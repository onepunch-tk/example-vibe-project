#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit) guard: main/master 에서 소스 편집 차단.
# 이미 기능 브랜치(feat/ fix/ ... prefix)면 즉시 통과한다.
# main/master 면 deny 하고, pr-flow 스킬로 기능 브랜치를 만든 뒤 재시도하도록 지시한다.
# set -e 는 일부러 빼서 비매칭 종료코드가 흐름을 끊지 않게 한다.
set -uo pipefail

input=$(cat)   # stdin(JSON) 보관 — 편집 대상 경로 검사에 사용

# 편집 대상 파일 경로 추출
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

# plan 파일(~/.claude/plans/...) 및 레포 루트 밖 파일은 "소스"가 아니므로 통과.
# 이 가드는 레포 내 소스를 main/master 에서 편집하지 못하게 하는 것이 목적이다.
if [ -n "$file_path" ]; then
  case "$file_path" in
    "$HOME"/.claude/plans/*) exit 0 ;;   # plan 파일은 항상 예외
  esac
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$repo_root" ]; then
    case "$file_path" in
      "$repo_root"/*) ;;        # 레포 안 → 계속 검사
      *) exit 0 ;;              # 레포 밖 → 가드 비대상
    esac
  fi
fi

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
