---
name: pr-flow
description: >-
  Run the full branch-to-PR flow: create/switch to a feature branch, commit
  with Conventional Commits, push, and open a GitHub pull request with a
  consistent, fully-filled template. Also use it just to get off main/master
  onto a properly named feature branch before starting work.
  Use this whenever the user wants to open/create/submit a PR or pull request,
  says they are "done" and want their work reviewed/merged, asks to "PR 만들어줘"
  / "PR 올려줘" / "풀리퀘 만들어줘", or says to push the work up for review. Also
  use it when work is finished on a branch and the natural next step is a PR,
  even if the user does not say the word "PR" explicitly. The skill safely gets
  off main/master first, commits with Conventional Commits, pushes, and opens
  the PR via gh. Prefer this over running raw `gh pr create` by hand so every PR
  follows the same template.
compatibility: Requires the `gh` CLI (authenticated) and a git repo with a GitHub remote.
---

# Create a Pull Request

Open a PR whose title and body follow one consistent template every time, so a
reviewer always knows where to find the summary, the changes, and how it was
tested. The body is **always** filled from the real diff and the **actual**
verification you ran — never from memory or assumption.

PR title and body are written in **English**. The title follows Conventional
Commits.

## Before you start: read the repo's rules

If a `CLAUDE.md` (or `AGENTS.md`) exists at the repo root, read it. It usually
defines commit conventions, branch rules, and which checks to run. Honor its
absolute rules — they override defaults here (e.g. "never commit to main").

## Workflow

Run these in order. Stop and ask the user only when a step is genuinely
ambiguous or destructive; otherwise proceed.

### 1. Survey the state

```bash
git branch --show-current
git status
git log --oneline -5
```

Understand what changed and where you are. If there are **no** changes (clean
tree and nothing ahead of the base branch), there is nothing to PR — tell the
user instead of creating an empty one.

### 2. Get off the base branch

If the current branch is `main` or `master` (or the repo's default branch),
**do not commit there.** Create a feature branch first — your uncommitted
changes follow you onto the new branch automatically:

```bash
git switch -c <type>/<short-kebab-summary>
```

Name it from the work, e.g. `feat/hover-tooltip`, `fix/feedback-500`. If the
repo's CLAUDE.md TODO already specifies a branch name for this work, use that.

If already on a feature branch, stay on it.

### 3. Commit

Stage the relevant changes and commit with a **Conventional Commits** message
(`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, with an optional
`(scope)`). Keep the subject under ~72 chars, imperative mood.

End the commit message with this trailer:

```
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

If there are already unpushed commits on the branch and they look complete,
don't re-commit — move on.

### 4. Push

```bash
git push -u origin <branch>
```

### 5. Build the PR body from reality

Determine the base branch (usually the default branch — `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`). Then inspect the full set of changes the PR will contain:

```bash
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

Copy `assets/pr-template.md` and fill **every** section from what you see:

- **Summary / Changes** — describe behavior from the actual diff, not a
  file-by-file restatement.
- **Testing** — this is the section reviewers trust, so it must be honest. Run
  the repo's checks (see CLAUDE.md cheatsheet, e.g. `npm run test`,
  `npm run typecheck`, `npm run lint`) and report the real outcome. If you did
  not or could not run something, say so explicitly. Never write "all tests
  pass" without having run them.
- **Related** — link issues/TODOs, else `None`.
- **Screenshots / Impact** — note UI changes or breaking changes, else `None`.

Leave the `<!-- comments -->` out of the final body.

### 6. Create the PR

Write the filled body to a temp file (avoids shell-escaping problems), then:

```bash
gh pr create --base <base> --title "<conventional title>" --body-file /tmp/pr-body.md
```

Add `--draft` when the PR is created automatically (e.g. by the auto-pr-on-stop
hook) or early while work is still ongoing, so it can be marked ready later.

Append this line to the end of the body before creating:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

If `gh pr create` reports a PR already exists for the branch, update it instead:
`gh pr edit --title ... --body-file ...`.

### 7. Report back

Give the user the PR URL that `gh` printed, and a one-line summary of what you
ran for the Testing section.

## Title examples

**Example 1:**
Work: added hover tooltips to the agent-loop page steps
Title: `feat(agent-loop): add step hover tooltips`

**Example 2:**
Work: feedback API returned 500 on empty body
Title: `fix(api/feedback): handle empty request body`

**Example 3:**
Work: added trackingId to error responses
Title: `feat(errors): include trackingId in error responses`
