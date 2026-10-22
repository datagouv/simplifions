---
name: simplifions-ship
description: "Implement one planned Simplifions issue: red-green-commit, proof through the feature map, PR, review loop. Run by a subagent that /simplifions-work spawns with `Run /simplifions-ship <ISSUE>`. Never merges."
---

Ship command for issues in Linear ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)). Executes provide-plan + implement-plan + PR + review loop for each issue. The PR is the end: Thomas reviews and merges, no agent merges.

## Usage
- `/simplifions-ship <issue1> <issue2> ...` - Ship listed issues sequentially
- `/simplifions-ship` (no args) - Resume active shipping session

## Behavior

Progress lives in `.notes/_ship-session.md` ([`session.md`](session.md): format, markers, resumption). Update it after each phase change.

- **With issue arguments ($1, $2, ...)**: create/update the session file with the issue list, then execute each issue sequentially through the phases below.
- **Without arguments**: if the session file has in-progress or pending items, resume from the current issue and phase as `session.md` § Resumption says. If no session, report "No active ship session".

## Phases (per issue)

1. **Setup** — mark the issue `in-progress`, phase `setup`. Read the issue from Linear to get the branch name; switch to the branch (create from an up-to-date `origin/main` if needed: `git fetch && git rebase origin/main`, `CLAUDE.md` § Commits). Locate the plan at `.notes/<branch_name>/plan.md` (strip prefix before `/` in branch names). Verify it exists and has no unanswered questions, `Flag:` line or FIXME markers; if it has, mark the issue `skipped` and move to the next one.
2. **Attach the plan to the issue** — phase `post-plan`. Upload `.notes/<branch_name>/plan.md` as a file on the issue (attach a file, title « Plan YYYY-MM-DD »). No comment: the issue's readers are not the plan's (`simplifions-commit/readers.md`). A scope decision the plan surfaced is the one thing worth a comment, as a question.
3. **Implement** — phase `implement`. Follow each step in the plan with the [red-green-commit](red-green-commit.md) cycle. Done when every plan step has its commit and `implement-plan.md` says so.
4. **Prove, push and create PR** — phase `push-pr`. Run the `/simplify` skill on the branch diff and apply its fixes (reuse, simplification, inlining); re-run tests to confirm still green. Then prove the change the way a user meets it: with the feature map (`.claude/skills/simplifions-verify/`, read its `SKILL.md` first) drive the feature the issue names, once, and keep the evidence path. A feature the map does not cover gets its file added in this PR. A PR that changes how an existing feature is reached (a link, a label, a page, a step of the path) or what proves it (what the page shows, what the database holds) updates that feature file and its drive in the same PR, as the « Carte de vérif : … » commits in `git log` do; the drive runs green before the PR. The evidence path is the PR body's third line. No proof, no PR: report `blocked` with what stopped the drive. Before the push: the full suite (`docker compose exec web bundle exec rspec`) and `docker compose exec web bin/rubocop` green, and `/accessibility:audit <file>` on every view or component created or modified (`CLAUDE.md` § Interface), its blocking non-conformities fixed. Push the branch to remote with `-u`, then `gh pr create` with the title and body of `simplifions-commit/pull-request.md`, whose lines carry the plan's « For the reviewer » items; a PR past a commit-by-commit read also gets `simplifions-commit/review-guide.md`. Wait for CI (`gh pr checks --watch`): red CI is not shipped, fix it on the branch. Record the PR number, phase `review`.
5. **Review loop** — [`review-loop.md`](review-loop.md): fresh `/simplifions-review` subagent, triage, re-plan + re-ship, round cap 3. Done when a round has no actionable finding or the cap is hit and reported.
6. **Next issue** — move to the next pending issue in the session; if none remain, the session is complete.

## Output

Templates in [`output.md`](output.md): resuming, after each issue, review cap hit, batch complete, error.
