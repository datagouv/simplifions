---
name: simplifions-plan
description: "Write or replan `.notes/<branch>/plan.md` for one Simplifions issue in Linear."
---

Plans one Linear issue, first plan or replan.

## Usage
- `/simplifions-plan <issue>` - Create or replan the plan for that issue (ID or URL)
- `/simplifions-plan` (no args) - Scan `.notes/*/plan.md` for unanswered questions or FIXMEs and replan those, one at a time

## Steps

1. Read [`one-rule.md`](one-rule.md). Every plan is measured against it; a plan that escalates complexity on its own is wrong even when it works.
2. Get the issue and its branch name ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)) → create or replan `.notes/<branch>/plan.md` in the format of [`plan-format.md`](plan-format.md). On a replan, read the comments appended to `issue.md` first: Thomas's answer settles a Question or the Flag, which is then removed.
3. Stop the moment the plan has questions or a flag — do NOT guess on ambiguity. Who answers is [`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides): a product question goes to the user, a technical go-ahead to Thomas as a comment the user posts on the issue. Done when the plan is ready, its questions are written in it, or the issue goes back to `/simplifions-challenge` or to the user.

## Output

Questions: show them, so the user can answer inline (product questions only). A flag or a technical go-ahead: say in one sentence that the issue waits for Thomas, and hand over the comment that asks him.
Ready: the branch name and a copy-pasteable `/simplifions-ship <issue>` line.
No `plan.md` (several stories, or a screen with no mockup): why, and the line to run next, or the mockup to ask the user for.
