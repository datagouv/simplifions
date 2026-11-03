# Red-green-commit

Read at phase 2 (implement) of `/simplifions-ship`, and again at each review round's re-ship. The test-writing reference is `/simplifions-tdd`.

- **First action of this phase**: copy the plan's step list verbatim into your todo list, one todo per step — paraphrasing the plan is how steps get silently dropped
- A step that only removes dead code (`remove <what>` in the plan) skips 1–4: remove, run the related tests, then 5–8.
- A step that changes structure with behaviour unchanged (`refactor <what>` in the plan) skips 1–4: refactor with the existing tests green before and after, then 5–8.
- At each step, follow the **red-green-commit** cycle:
  1. **Red**: Write the failing test(s) specified in the plan step. When an outside rule drives the change (a publication date, a threshold), one example per real case the rule produces, the why in its name. A test proves what the change does, never that code the diff removed is gone: the diff shows that. A removal the user sees (a button, a link, a page) is a change in behaviour: its test checks that the screen no longer offers it. JavaScript has no test tool here: its red is a feature-map drive that fails before the change (`REVIEW.md` § 7). A fix that stops a wrong effect tests that effect, in the case that motivated it. No spy (`have_received`) on a call whose result another assertion already checks
  2. Run the test (`docker compose exec web bundle exec rspec <file>`) — confirm it fails for the expected reason (not a typo/syntax error)
  3. **Green**: Implement the minimum code needed to make the test pass
  4. Run the test — confirm it passes. Then the two-edit check: a hand mutation of the behaviour the step adds (revert its key line, flip its condition) turns the test red, then undo it. A test that survives the mutation is hollow and reaches review as a critical finding: tighten it now
  5. **Refactor = less indirection, not fewer lines** (the step's own code; the plan's last step, Simplify, covers the whole change): each test and each method reads top to bottom without jumping around. A table of lambdas, `instance_exec`, a helper returning tuples to destructure, or an inline `begin…end` memo is not a refactor: if this step wrote one, rewrite it. Never introduce an abstraction the plan doesn't name (a `shared_examples` or a `build_x` memo reader is readability, not an abstraction); if one feels necessary mid-step, stop and flag it instead of improvising. Re-run tests to confirm still green
  6. Run broader quality checks (`docker compose exec web bin/rubocop -a`, related test files)
  7. **Commit**: tests and implementation ship in the same commit, with the message written by `/simplifions-commit`: the plan step is context the log reader does not have
  8. Update the session's Plan step
- **Spike exception**: If the plan was flagged as a spike during `/simplifions-challenge`, the red-green cycle is optional — but note skipped tests in the plan file so review catches them.
- **A change the plan names but the step could do without gets its own commit**, before the commit that uses it: a boy-scout cleanup, a new hook in a base class, a rename. Folded into a feature commit, it reads as a required change.
- **Design tripwire**: when a plan step's design does not hold (the approved construct breaks a test or hides a failure), stop: the report carries a comment asking Thomas, with what broke, for the user to post on the issue ([`simplifions-work` § Linear](../simplifions-work/SKILL.md#linear)), and the session is `blocked`. Never swap in another construct, least of all one the plan's `Design:` line rejected: the shape is the planner's call.
- **Scope tripwire**: the diff stops at the issue's scope, never at a line count. A change the plan did not name goes in the session file and to the user; a diff that outgrows a commit-by-commit read is guided as `simplifions-commit/pull-request.md` says, never split into a PR that ships half a functionality.
- If tests fail unrelated to the plan, note them and continue
- No blocking on flaky feature tests
- **Learning capture**: a non-trivial problem met and solved during implementation (unexpected behaviour, framework gotcha, debugging dead-end) becomes a proposed change to `CLAUDE.md` or to a `simplifions-*` skill, under the plan's « For the reviewer » so it reaches the PR body: Thomas decides whether it lands. Never the agent's local memory: the next contributor's session would not see it.
