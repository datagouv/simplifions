---
name: simplifions-review
description: "Paranoid two-pass code review of a Simplifions branch, PR, or files, run by a fresh agent before Thomas reviews. Use whenever the user asks to review a PR, a pull request URL, a branch, or files (\"can you review…\", \"est-ce qu'on peut review…\"), or to review a PR's design together (\"relis cette PR avec moi\", \"review de conception\")."
---

Paranoid code review. Two-pass structural audit of changes, designed to catch bugs that pass CI but blow up in production.

## Usage
- `/simplifions-review` - Review current branch changes against origin/main
- `/simplifions-review <PR-number>` or `/simplifions-review <PR URL>` - Review a specific PR (also triggered by a plain request such as "peux-tu review https://github.com/org/repo/pull/504")
- `/simplifions-review <file1> <file2> ...` - Review specific files
- `/simplifions-review design <PR>` - Design review in conversation with the user, ending with a shareable page ([`design-review.md`](design-review.md)); also triggered by "relis cette PR avec moi", "review de conception"

## Purpose

This is the **paranoid staff engineer brain**. Not a style review, not a linting pass. This catches structural bugs: race conditions, N+1 queries, trust boundary violations, silent failures, and logic errors.

## Steps

1. **Gather the diff**
   - No args: `git fetch && git diff origin/main...HEAD` (all changes on current branch)
   - PR number or URL: fetch PR diff via `gh pr diff <number-or-url>`; past a handful of commits read them in order (`gh pr view --json commits`, then `git show` each) and follow the review guide when the body links one, since the commits are the author's reading path; and the author via `gh pr view <number-or-url> --json author -q .author.login` — the report prints it, so whoever relays the findings knows whether the fix is ours to delegate or the author's (Apistration PR #383, 2026-09-15: a team PR framed as ours to fix)
   - Specific files: `git diff origin/main -- <files>`
2. **Asked versus built**: [`asked.md`](asked.md) — the ask as a checklist from the issue, then the diff marked against it. Done when every line carries delivered / missing / deviates and the extras are listed.
3. **Read the checklist**: `.claude/review-checklist.md` if the project has one (project-specific overrides), else [`checklist.md`](checklist.md).
4. **Launch the Codex second opinion (background)**. Start it before your own passes so it runs in parallel (review mode is read-only by design):
   - Branch: `mkdir -p .notes/<branch>` (branch name with the prefix before `/` stripped, as for the plan), then `codex exec review --base origin/main > .notes/<branch>/codex-review.md 2>&1`
   - PR number or URL: never switch the session's checkout (ship works there). Check the PR out in a separate worktree: `git fetch origin pull/<n>/head && git worktree add --detach <scratch>/pr-<n> FETCH_HEAD`, run the same command from there with the output path pointing at this checkout's `.notes/<branch>/`, then `git worktree remove <scratch>/pr-<n>`
   - Specific files: not run (`--base` takes no prompt), say so under CODEX SECOND OPINION
   Run it with `run_in_background`; collect the file after Pass 4. If `codex` is missing or fails (quota, login, "Review blocked … sandbox could not start"), say so under CODEX SECOND OPINION and continue — the second opinion is additive, never blocking. Never pass `--dangerously-bypass-approvals-and-sandbox` to get past a sandbox error: review mode then runs commands unsandboxed (it will happily run the test suite).
5. **Run the four passes** of the checklist in order: CRITICAL, INFORMATIONAL, DESIGN, SIMPLICITY. A pass is done when every category has been checked against the whole diff.
6. **Merge the Codex opinion**. Read `codex-review.md`. For each Codex finding: verify it against the code (same bar as your own — concrete failure scenario or drop it). Agreements get a "(also Codex)" tag on your finding; new confirmed findings go under CODEX SECOND OPINION; findings you reject get a one-line rebuttal there so the user sees the disagreement, not silence.
7. **Diagram the data flow** (if the diff touches a data pipeline, request handler, or multi-step process): ASCII diagram, mark where validation happens (or doesn't), mark where errors can occur and how they're handled.
8. **Write the report** in the format of [`output.md`](output.md).

## Rules

- No style nits a linter catches. Pass 2 Readability is not a nit.
- Every critical finding must include a concrete failure scenario ("when X happens, Y breaks because Z").
- Don't flag things that are already covered by existing tests (read the test files).
- If the diff is clean, say "no issues found, ship it" — don't invent problems. Clean code that misses a line of the ask is not clean: the verdict is `partial`.
- Be specific. "This could be a problem" is useless. "This N+1 fires on the index page with 50+ records and will timeout" is useful.
- Read surrounding code for context before flagging — the "bug" might be handled elsewhere.
