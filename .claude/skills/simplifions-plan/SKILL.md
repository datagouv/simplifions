---
name: simplifions-plan
description: "Write or replan `.notes/<branch>/plan.md` for Simplifions issues in Linear."
---

Plan command for issues in Linear ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)). Handles both initial planning and replanning.

## Usage
- `/simplifions-plan <issue1> <issue2> ...` - Create or replan for listed issues (IDs or URLs)
- `/simplifions-plan` (no args) - Resume active session OR replan plans with unanswered questions

## Steps

1. Read [`one-rule.md`](one-rule.md). Every plan is measured against it; a plan that escalates complexity on its own is wrong even when it works.
2. Open or resume the session file ([`session.md`](session.md)).
   - **With issue arguments**: write the session file with the issue list. Per issue: read the issue from Linear → get branch name → create/replan/skip at `.notes/<branch>/plan.md` in the format of [`plan-format.md`](plan-format.md) → update session status.
   - **Without arguments**: resume from the session file if pending items exist; else scan `.notes/*/plan.md` for unanswered questions / FIXMEs and replan those. A plan waiting for Thomas: read the issue's comments; his answer settles the Question or the Flag, which is then removed.
3. Stop the moment a plan has questions or a flag — do NOT guess on ambiguity. Who answers is [`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides): a product question goes to the user, a technical go-ahead to Thomas as a comment on the issue. Done when every listed issue is `ready`, `has-questions`, or skipped in the session file.

## Output

On stop: show progress list + the questions, so the user can answer inline (product questions only; a technical go-ahead says the issue waits for Thomas).
On batch complete: list ready issues with branch names + a copy-pasteable `/simplifions-ship SIM-123 SIM-124` line, and any still-has-questions issues.
