# Plan format — one screen max

`.notes/<branch_name>/plan.md`, the prefix before `/` stripped from the branch name.

```markdown
# <ISSUE-ID> — <title>

<one-line restatement of the outcome>

Kind: fills <system> | new system | isolated — <why, one line>   ← one-rule.md § What are we building

## Diagram
<5-line ASCII of the flow: happy path + error path. So a reader grasps the change in a second — describe the design, never justify it.>

## Steps
1. <failing test to write> → <change that makes it pass>
2. ...

## Size
~X lines, Y files, N commits in reading order   ← an estimate, not a cap: the PR's grain is `../simplifions-challenge/slices.md`; the commits are the reviewer's path. Sized from the issue's appetite when /simplifions-challenge wrote one.

Entry points: <the routes, jobs or commands that reach the objects this plan changes>
Design: grid — ok | <finding> → <change in the steps>

## For the reviewer   ← only if any: technical choices made and doubts left, carried to the PR body for Thomas
- ...

## Questions          ← only if any; presence = has-questions
- ... → recommended: ...   ← decisions only, each with its recommended answer
Flag: ...             ← only if you believe simple is insufficient (one sentence)
```

- **TDD is the default.** Each step = failing test + the behavior change that makes it pass, together; a step that only removes dead code is written `remove <what>` (a removal the user sees gets a failing test, like any other change), and a step that changes structure with behaviour unchanged (the preparatory refactor the kind calls for) `refactor <what>`: neither has a failing test. A step with no unit test (CSS, JS) names its red: a system test, or a `/simplifions-verify` check that fails before the change. Never a trailing "add tests" step. Spike exception only if `/simplifions-challenge` flagged it — note it in the plan.
- **Steps are vertical slices** ([`../simplifions-challenge/slices.md`](../simplifions-challenge/slices.md)). Each step leaves a behaviour observable end to end, through every layer it needs, never a layer alone: no "model" step then "controller" step then "view" step. A `remove` or `refactor` step is the only exception.
- **An issue that holds more than one story** (the one-sentence test of `slices.md`) goes back to `/simplifions-challenge` (its Split Granularity step): no `plan.md` is written.
- Explore the codebase before planning; plans reference real files.
- A screen with a mockup (a Claude artifact, or captures with their intentions in the issue) is built from the mockup: look at it before writing the steps, and name it in the step. A difference from it goes under Questions, never a default component in its place. A change to a screen's layout or flow with no mockup: no `plan.md` is written; ask the user for one (a UX question). A change of wording only needs no mockup.
- A fact the code, the app or the issue can give is looked up, never put under Questions; only decisions go to the user.
- A technical doubt the rules settle goes under « For the reviewer », not under Questions ([`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides)).
- Lines with FIXME must be addressed when replanning.

## Design check

After the steps are written, list on the `Entry points:` line every route, job or command that reaches the objects the plan changes (grep the callers, the routes file, the controllers). Behaviour that belongs to one of them cannot live in an object they share. Then walk [`../simplifions-review/design-grid.md`](../simplifions-review/design-grid.md) against the planned changes. A finding changes the steps: it moves code to its owner, removes a second path, or adds the preparatory refactor the kind calls for (`one-rule.md`). Record the result on the `Design:` line.

## Fresh-eyes check

Before the plan is ready (no Questions, no Flag), spawn a subagent on `sonnet` with only the issue + draft plan: "Propose a design with half the moving parts, or the same behaviour owned by a different object." A smaller version of the same shape keeps a wrong owner; asking for another owner is what catches it. If it finds a simpler shape or a better owner, that becomes the plan. If its shape contradicts a rule (`one-rule.md`, the project `CLAUDE.md`), never reject it on the rule alone: keep the shape the rules call for and put the other one under « For the reviewer », both shapes in one line each, so Thomas decides at review. Exploration and fresh-eyes run on the smaller model on purpose; judgment stays on the main one.
