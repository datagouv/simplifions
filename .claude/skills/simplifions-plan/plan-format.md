# Plan format — one screen max

Read at step 2 of `/simplifions-plan`, when writing or replanning `.notes/<branch_name>/plan.md` (strip prefix before `/` in branch names).

```markdown
# <ISSUE-ID> — <title>

<one-line restatement of the outcome>

Kind: trivial | fills <system> | new system | isolated — <why, one line>   ← one-rule.md § What are we building

## Diagram
<5-line ASCII of the flow: happy path + error path. So a reader grasps the change in a second — describe the design, never justify it.>

## Steps
1. <failing test to write> → <change that makes it pass>
2. ...
N. Simplify: after green, what can be deleted, inlined, or collapsed?

## Size
~X lines, Y files, N commits in reading order   ← an estimate, not a cap: one PR per functionality, self-sufficient; the commits are the reviewer's path. Sized from the issue's appetite when /simplifions-challenge wrote one.

Entry points: <the routes, jobs or commands that reach the objects this plan changes>
Design: grid — ok | <finding> → <change in the steps>

## For the reviewer   ← only if any: technical choices made and doubts left, carried to the PR body for Thomas
- ...

## Questions          ← only if any; presence = has-questions
- ...
Flag: ...             ← only if you believe simple is insufficient (one sentence)
```

- **TDD is the default.** Each step = failing test + the behavior change that makes it pass, together. Never a trailing "add tests" step. Spike exception only if `/simplifions-challenge` flagged it — note it in the plan.
- Explore the codebase before planning; plans reference real files.
- Lines with FIXME must be addressed when replanning.
- A technical doubt the rules settle goes under « For the reviewer », not under Questions ([`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides)).

## Design check

Kind trivial: skip it, `Design: n/a`.

After the steps are written, list on the `Entry points:` line every route, job or command that reaches the objects the plan changes (grep the callers, the routes file, the controllers). Behaviour that belongs to one of them cannot live in an object they share. Then walk [`../simplifions-review/design-grid.md`](../simplifions-review/design-grid.md) against the planned changes. A finding changes the steps: it moves code to its owner, removes a second path, or adds the preparatory refactor the kind calls for (`one-rule.md`). Record the result on the `Design:` line.

## Fresh-eyes check (non-trivial plans only)

Before marking `ready`, spawn a subagent on `sonnet` with only the issue + draft plan: "Propose a design with half the moving parts." If it finds a simpler shape, that becomes the plan. If its shape contradicts a rule (`one-rule.md`, the project `CLAUDE.md`), never reject it on the rule alone: keep the shape the rules call for and put the other one under « For the reviewer », both shapes in one line each, so Thomas decides at review. Exploration and fresh-eyes run on the smaller model on purpose; judgment stays on the main one.
