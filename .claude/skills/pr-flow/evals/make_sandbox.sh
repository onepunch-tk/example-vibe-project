#!/usr/bin/env bash
# Build an isolated sandbox git repo for a pr-flow eval.
# Usage: make_sandbox.sh <dest_dir> <scenario>
# Scenarios: on-main-feature | on-branch-committed | main-bugfix-with-todo
#
# Each sandbox:
#  - is a real git repo with a LOCAL bare "origin" (so `git push` works offline)
#  - has NO GitHub remote, so `gh pr create` will fail (intentional)
#  - has a tiny but realistic Next.js-ish project + CLAUDE.md
#  - npm scripts are offline echoes so `npm run test/typecheck/lint` succeed deterministically
set -euo pipefail

DEST="$1"
SCENARIO="$2"

rm -rf "$DEST"
mkdir -p "$DEST"
WORK="$DEST/repo"
BARE="$DEST/origin.git"
mkdir -p "$WORK"

git init -q -b main "$WORK"
git -C "$WORK" config user.email "dev@example.com"
git -C "$WORK" config user.name "Dev"

# --- common project skeleton -------------------------------------------------
cat > "$WORK/package.json" <<'JSON'
{
  "name": "example-vibe-project",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "echo '✓ 12 passed (12)'",
    "test:watch": "echo watch",
    "typecheck": "echo 'tsc --noEmit: no errors'",
    "lint": "echo 'eslint: no problems'",
    "format": "echo 'prettier ok'"
  }
}
JSON

cat > "$WORK/CLAUDE.md" <<'MD'
# CLAUDE.md

## 1. 절대 규칙
- 절대 `console.log`를 production 코드에 두지 말 것. `logger.ts` 사용.
- 절대 `main` or `master` branch에 직접 커밋하지 말 것.
- 절대 에러 처리시 `new Error`를 사용하지 말 것. `errors.ts` 사용.

## 2. 명령어 치트시트
```bash
npm run test        # 전체 테스트
npm run typecheck   # 타입체크
npm run lint        # 린트
```

## 5. 지금 진행 중 (TODO)
- [ ] `/agent-loop` 페이지에 단계별 호버 툴팁 추가  (branch: feat/hover-tooltip)
- [ ] 에러 응답 데이터 보강. feedback API 빈 body 처리 + trackingId 추가 (이슈 #5, branch: feat/error-response-data)
MD

mkdir -p "$WORK/app/agent-loop" "$WORK/app/api/feedback" "$WORK/components" "$WORK/lib"
cat > "$WORK/lib/logger.ts" <<'TS'
export const logger = {
  info: (m: string, meta?: unknown) => process.stdout.write(JSON.stringify({ level: "info", m, meta }) + "\n"),
  error: (m: string, meta?: unknown) => process.stderr.write(JSON.stringify({ level: "error", m, meta }) + "\n"),
};
TS
cat > "$WORK/lib/errors.ts" <<'TS'
export class AppError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}
TS
cat > "$WORK/app/agent-loop/page.tsx" <<'TSX'
export default function AgentLoopPage() {
  const steps = ["plan", "act", "observe"];
  return (
    <ol>
      {steps.map((s) => (
        <li key={s}>{s}</li>
      ))}
    </ol>
  );
}
TSX
cat > "$WORK/app/api/feedback/route.ts" <<'TS'
import { AppError } from "@/lib/errors";

export async function POST(req: Request) {
  const body = await req.json();
  return Response.json({ ok: true, body });
}
TS

git -C "$WORK" add -A
git -C "$WORK" commit -qm "chore: project skeleton"

# bare origin + push main
git init -q --bare "$BARE"
git -C "$WORK" remote add origin "$BARE"
git -C "$WORK" push -q -u origin main

# --- per-scenario state ------------------------------------------------------
case "$SCENARIO" in
  on-main-feature)
    # finished work, still on main, uncommitted
    cat > "$WORK/components/StepTooltip.tsx" <<'TSX'
export default function StepTooltip({ label, hint }: { label: string; hint: string }) {
  return (
    <span title={hint} className="step-tooltip">
      {label}
    </span>
  );
}
TSX
    cat > "$WORK/app/agent-loop/page.tsx" <<'TSX'
import StepTooltip from "@/components/StepTooltip";

const HINTS: Record<string, string> = {
  plan: "다음 행동을 계획합니다",
  act: "도구를 호출합니다",
  observe: "결과를 관찰합니다",
};

export default function AgentLoopPage() {
  const steps = ["plan", "act", "observe"];
  return (
    <ol>
      {steps.map((s) => (
        <li key={s}>
          <StepTooltip label={s} hint={HINTS[s]} />
        </li>
      ))}
    </ol>
  );
}
TSX
    ;;

  on-branch-committed)
    # already on feature branch with a committed change ahead of main
    git -C "$WORK" switch -q -c fix/feedback-empty-body
    cat > "$WORK/app/api/feedback/route.ts" <<'TS'
import { AppError } from "@/lib/errors";

export async function POST(req: Request) {
  const text = await req.text();
  if (!text) {
    throw new AppError(400, "EMPTY_BODY", "feedback body is required");
  }
  const body = JSON.parse(text);
  return Response.json({ ok: true, body });
}
TS
    git -C "$WORK" add -A
    git -C "$WORK" commit -qm "fix(api/feedback): reject empty request body with 400"
    ;;

  main-bugfix-with-todo)
    # finished bug fix, still on main, uncommitted
    cat > "$WORK/app/api/feedback/route.ts" <<'TS'
import { AppError } from "@/lib/errors";

export async function POST(req: Request) {
  const text = await req.text();
  if (!text) {
    throw new AppError(400, "EMPTY_BODY", "feedback body is required");
  }
  const body = JSON.parse(text);
  return Response.json({ ok: true, body });
}
TS
    ;;

  *)
    echo "unknown scenario: $SCENARIO" >&2
    exit 1
    ;;
esac

echo "sandbox ready: $WORK (scenario=$SCENARIO, branch=$(git -C "$WORK" branch --show-current))"
