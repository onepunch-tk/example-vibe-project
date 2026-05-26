#!/usr/bin/env python3
"""Grade pr-create eval outputs against assertions. Writes grading.json per run."""
import json, re, os, sys

ITER = os.path.dirname(os.path.abspath(__file__))

SHARED = [
    "PR body has all 5 standard sections (Summary, Changes, Testing, Related, Screenshots/Impact)",
    "PR body prose is in English (low Hangul ratio)",
    "No leftover HTML template comments (<!-- -->) in final body",
    "Title follows Conventional Commits",
    "Generated-with-Claude-Code footer present",
    "Testing section reflects actually-run checks (names a check + a real result, not blank/unchecked)",
]
PER_EVAL = {
    "eval-0-on-main-feature": [
        "Branched off main onto a feature branch",
        "Commit message includes Co-Authored-By trailer",
    ],
    "eval-1-on-branch-committed": [
        "Did NOT create a new branch (stayed on the existing feature branch)",
        "Only one commit ahead of main (no redundant empty commit)",
    ],
    "eval-2-main-bugfix-with-todo": [
        "Branched off main onto a feature branch",
        "Related section references issue #5",
        "Related section references the CLAUDE.md TODO",
    ],
}

def hangul_ratio(s):
    h = len(re.findall(r"[가-힣]", s))
    letters = len(re.findall(r"[A-Za-z가-힣]", s))
    return (h / letters) if letters else 0.0

def grade_run(eval_dir, run):
    out = os.path.join(ITER, eval_dir, run, "outputs")
    body = open(os.path.join(out, "PR_BODY.md")).read() if os.path.exists(os.path.join(out,"PR_BODY.md")) else ""
    title = open(os.path.join(out, "PR_TITLE.txt")).read().strip() if os.path.exists(os.path.join(out,"PR_TITLE.txt")) else ""
    gs = open(os.path.join(out, "git-state.txt")).read() if os.path.exists(os.path.join(out,"git-state.txt")) else ""
    exp = []
    def add(text, passed, evidence):
        exp.append({"text": text, "passed": bool(passed), "evidence": evidence})

    # --- shared ---
    secs = {
        "Summary": bool(re.search(r"(?im)^#{1,3}\s+Summary\b", body)),
        "Changes": bool(re.search(r"(?im)^#{1,3}\s+Changes\b", body)),
        "Testing": bool(re.search(r"(?im)^#{1,3}\s+Testing\b", body)),
        "Related": bool(re.search(r"(?im)^#{1,3}\s+Related\b", body)),
        "Screenshots/Impact": bool(re.search(r"(?im)^#{1,3}\s+Screenshots\s*/\s*Impact\b", body)),
    }
    add(SHARED[0], all(secs.values()), "sections found: " + json.dumps(secs))

    hr = hangul_ratio(body)
    add(SHARED[1], hr < 0.15, f"hangul ratio={hr:.2f} (threshold <0.15)")

    has_comment = "<!--" in body
    add(SHARED[2], not has_comment, "no '<!--' found" if not has_comment else "leftover '<!--' present")

    cc = bool(re.match(r"^(feat|fix|chore|refactor|docs|test|perf|build|ci|style)(\(.+\))?: .+", title))
    add(SHARED[3], cc, f"title={title!r}")

    footer = "Generated with" in body and "claude.com/claude-code" in body
    add(SHARED[4], footer, "footer present" if footer else "footer missing")

    # testing section text
    m = re.search(r"(?ims)^#{1,3}\s+Testing\b(.*?)(^#{1,3}\s+|\Z)", body)
    tsec = m.group(1) if m else ""
    names_check = bool(re.search(r"npm run (test|typecheck|lint)|tsc|eslint|vitest", tsec))
    has_result = bool(re.search(r"passed|no errors|no problems|통과|✓|\bpass\b|→", tsec))
    unchecked = bool(re.search(r"\[\s\]", tsec)) and not has_result
    testing_ok = names_check and has_result and not unchecked
    add(SHARED[5], testing_ok, f"names_check={names_check} has_result={has_result} unchecked_only={unchecked}; testing='{tsec.strip()[:120]}'")

    # --- per eval ---
    branch_m = re.search(r"BRANCH:\s*(\S+)", gs)
    branch = branch_m.group(1) if branch_m else "?"
    log_lines = [l for l in gs.splitlines() if re.match(r"^[0-9a-f]{7,} ", l)]
    if eval_dir == "eval-0-on-main-feature":
        add(PER_EVAL[eval_dir][0], branch not in ("main","master","?"), f"branch={branch}")
        add(PER_EVAL[eval_dir][1], "Co-Authored-By" in gs, "trailer in last commit" if "Co-Authored-By" in gs else "no trailer")
    elif eval_dir == "eval-1-on-branch-committed":
        add(PER_EVAL[eval_dir][0], branch == "fix/feedback-empty-body", f"branch={branch}")
        # commits ahead of main = total log lines minus skeleton(1) ; expect exactly 1 feature commit
        feature_commits = max(0, len(log_lines) - 1)
        add(PER_EVAL[eval_dir][1], feature_commits == 1, f"feature commits ahead={feature_commits} (log lines={len(log_lines)})")
    elif eval_dir == "eval-2-main-bugfix-with-todo":
        add(PER_EVAL[eval_dir][0], branch not in ("main","master","?"), f"branch={branch}")
        m2 = re.search(r"(?ims)^#{1,3}\s+Related\b(.*?)(^#{1,3}\s+|\Z)", body)
        rel = m2.group(1) if m2 else ""
        add(PER_EVAL[eval_dir][1], "#5" in rel, f"related='{rel.strip()[:100]}'")
        add(PER_EVAL[eval_dir][2], ("CLAUDE.md" in rel or "TODO" in rel), f"related mentions TODO/CLAUDE.md: {'CLAUDE.md' in rel or 'TODO' in rel}")

    passed = sum(1 for e in exp if e["passed"])
    total = len(exp)
    res = {"eval": eval_dir, "run": run, "passed": passed, "total": total,
           "expectations": exp,
           "summary": {"passed": passed, "failed": total - passed, "total": total,
                       "pass_rate": round(passed / total, 4) if total else 0.0}}
    json.dump(res, open(os.path.join(ITER, eval_dir, run, "grading.json"), "w"), indent=2, ensure_ascii=False)
    return res

if __name__ == "__main__":
    for ed in PER_EVAL:
        for run in ("with_skill","without_skill"):
            r = grade_run(ed, run)
            print(f"{ed}/{run}: {r['passed']}/{r['total']}")
