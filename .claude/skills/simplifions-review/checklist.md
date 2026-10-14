# Built-in checklist

Read at step 3 of `/simplifions-review` when the project has no `.claude/review-checklist.md`. Each pass lists what to look for; the bar for a finding is in `SKILL.md` § Rules.

## Pass 1: CRITICAL
Issues that will break production, lose data, or create security holes.

For each finding: the failure scenario (when does this blow up?), written as `output.md` says: behaviour, steps, result, no code reference and no fix.

Categories:
- **SQL safety**: Raw queries, missing indexes on new columns, N+1 queries, missing transactions where needed
- **Race conditions**: TOCTOU bugs, concurrent access without locking, shared mutable state
- **Trust boundaries**: User input flowing into queries/commands without validation, LLM output treated as trusted, external API responses used without verification
- **Silent failures**: Bare rescue/catch blocks, swallowed errors, missing error handling on external calls
- **Data loss**: Destructive migrations without backfill, cascade deletes, missing null checks on critical paths
- **Auth/authz gaps**: Missing authorization checks, privilege escalation paths, exposed endpoints
- **Untested new code paths**: New methods, branches, or behaviors introduced without a corresponding test. This is not "low coverage" hand-wringing — flag only when a specific new path has zero direct test exercising it. TDD was violated; bugs will ship. (Exception: spike PRs explicitly flagged as such.)
- **Unproven premise**: Name the one fact the change is safe or effective because of, and how it is proven (test, drive, measurement, or assumed). If that fact is unproven for the case that motivated the PR, it is CRITICAL and the verdict cannot be ship it.

## Pass 2: INFORMATIONAL
Issues worth knowing about but not blocking.

Categories:
- **Conditional complexity**: Nested conditions that hide logic bugs, boolean expressions that could be simplified
- **Missing edge cases**: Nil/null/empty/zero handling, unicode, timezone, pagination boundaries
- **Test gaps**: Happy-path-only tests, missing error case tests, weak assertions (promoted to CRITICAL if an entire new code path has zero tests)
- **Performance**: Unbounded queries, missing pagination, loading associations unnecessarily
- **Dead code**: Unused variables, unreachable branches, commented-out code
- **Naming/clarity**: Misleading names, magic numbers, unclear intent (only when it could cause bugs; test names and readable code: see Readability)
- **Readability** (app code and specs, no bug risk needed; the cost is a reviewer's time; RSpec/Ruby examples): double-negative or vague `describe`/`context` names; several cases driven by a data table and metaprogramming instead of one `context` per case with its stub in a `before` and a `shared_examples` taking the expected value; helpers returning tuples to destructure; vague assertions (`be >= 400` where the status is known); memoized readers with an inline block instead of `@x ||= build_x`

## Pass 3: DESIGN
Walk [`design-grid.md`](design-grid.md) on the diff and on what it plugs into (callers, base classes, every other user of the classes it changes). Open the section with the families checked, even when nothing is found.
- A finding says in plain words who decides or holds what today, who should, and what disappears if it moves (`output.md`: no fix, no code names). The target sketch belongs to `/simplifions-review design`.
- Merge findings into the output under a "DESIGN" section between CRITICAL and INFORMATIONAL

## Pass 4: SIMPLICITY (over-engineering)
Complexity that costs more than it pays, measured against [the one rule](../simplifions-plan/one-rule.md). Same rule as CRITICAL: each finding needs a concrete cost statement, not a vibe.

Categories:
- **Configuration over convention**: config flags, option hashes, initializers, or custom plumbing where a Rails convention/built-in does the job — name the built-in that replaces it
- **Speculative generality**: params, options, config flags, or branches nothing uses today
- **Single-caller indirection**: a class/service/method with exactly one call site that could be inlined (a `build_x` behind an `@x ||=` memo, or a `shared_examples`, is readability, not indirection)
- **Impossible-state defense**: guards/rescues for states that cannot occur given the actual callers
- **Homeless abstraction**: new class/module created where existing code had a natural home

A construct that removes a mechanism (a second path, a list, a copy), named as such in the plan, is neither single-caller indirection nor a homeless abstraction.
- **Kind mismatch**: the shape does not match what is being built (`one-rule.md` § What are we building): a system built for a trivial change, or a graft where an existing system needed widening
- **Plan drift**: diff significantly larger than the plan's size estimate (`.notes/<branch>/plan.md`) — name where the growth happened. Lines added by a readability rewrite are not drift

Each finding states the deletion payoff ("inlining this removes 40 lines and one file"). Never flag a Readability rewrite in this pass.
