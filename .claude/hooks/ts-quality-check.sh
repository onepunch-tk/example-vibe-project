#!/usr/bin/env bash
# ts/tsx 저장(Edit/Write/MultiEdit) 직후 실행되는 PostToolUse 훅.
# 순서: 1) lint(eslint --fix) → 2) format(prettier --write) → 3) typecheck(tsc --noEmit)
# 고칠 수 있는 건 자동 수정하고, 남은 오류만 stderr로 보고(exit 2)하여 Claude가 수정하게 한다.
set -uo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

# stdin JSON에서 편집된 파일 경로 추출
file=$(cat | jq -r '.tool_input.file_path // empty')

# .ts / .tsx 만 대상, 그 외(또는 삭제된 파일)는 조용히 스킵
case "$file" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

report=""

# 1. lint — 자동수정 후 남은 오류 수집 (npm warn 라인 제거)
lint_out=$(npx --no-install eslint --fix "$file" 2>&1)
lint_code=$?
lint_out=$(printf '%s' "$lint_out" | grep -v '^npm warn')
[ "$lint_code" -ne 0 ] && report+="[lint] 자동수정 후 남은 오류:\n${lint_out}\n\n"

# 2. format — 자동수정 (조용히)
npx --no-install prettier --write "$file" >/dev/null 2>&1

# 3. typecheck — 전체 프로젝트, 자동수정 불가
type_out=$(npx --no-install tsc --noEmit 2>&1)
type_code=$?
type_out=$(printf '%s' "$type_out" | grep -v '^npm warn')
[ "$type_code" -ne 0 ] && report+="[typecheck] 타입 오류 (직접 수정 필요):\n${type_out}\n\n"

if [ -n "$report" ]; then
  printf '%b' "$report" >&2
  exit 2
fi
exit 0
