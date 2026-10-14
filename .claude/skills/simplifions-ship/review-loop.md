# Review loop

Read at phase 5 (review) of `/simplifions-ship`.

- Spawn a review subagent (fresh context, main model: review is judgment) whose prompt is exactly:
  ```
  Run /simplifions-review <pull_request_link>
  ```
  Nothing else — the reviewer forms its own view from the PR alone. `/simplifions-review` carries the checklist, the four passes and the Codex second opinion, so this phase adds nothing on top of it. Save the subagent's report **verbatim** to `.notes/<branch_name>/review-round-N.md` (the `simplifions-review/output.md` shape, headings and numbering kept), then append `## Triage` with one line per finding: `N. fixed | rebutted: <why> | deferred: <where>`. A paraphrased round file cannot be counted.
- Triage the report (ASKED vs BUILT lines marked missing, deviates, unclear, unproven or extra, then CRITICAL, DESIGN, SIMPLICITY, Readability and confirmed CODEX findings; a "Codex: not run" line is noted in the session file `## Notes` and does not block the loop):
  - **No actionable findings** and CI green → mark issue `shipped` (record the round count), move to next issue
  - **Actionable findings** → fix on the same branch:
    1. **Challenge each finding first.** A finding is a claim written as behaviour, steps and result, with no code reference and no fix (`simplifions-review/output.md`). Locate the code yourself, then turn its steps into a failing test. It fails → the finding stands and that test is the red step. It passes, or the steps cannot be built → rebutted in review-round-N.md with what was tried. A finding in the ask (missing, deviates, unclear, unproven) is checked against the issue, not rebutted by a test: an unclear line is settled by a test or a drive that shows it, an unproven one by the feature-map drive. A Readability or DESIGN finding is checked by reading the code and fixed without a red step, as a behaviour-preserving change; tests stay green. A DESIGN fix that reshapes more than the PR (a refactor of the system it fills) is a flag for Thomas, written in the PR body, not a re-plan step.
    2. **Re-plan**: append a `## Review round N` section to `.notes/<branch_name>/plan.md` — same format and same one rule as /simplifions-plan ([`../simplifions-plan/one-rule.md`](../simplifions-plan/one-rule.md); one step per standing finding: its failing test → fix; simplest fix only, flag rather than escalate). An **extra** the user wants kept is a scope change: ask the user, do not decide; a **missing** line is never rebutted, it is built or the issue is re-scoped by the user.
    3. **Re-ship**: implement the new steps with the [red-green-commit](red-green-commit.md) cycle, push to the same branch (the PR updates) and wait for CI green again. A fix goes into the commit whose story it tells (`/simplifions-commit` step 3: `--fixup`, autosquash, `--force-with-lease`) and into the file whose behaviour it covers, never into a file because its setup happens to make the test pass
    4. Spawn a **fresh** review subagent on the updated PR with the same prompt, repeat
- **Round cap: 3.** If findings remain after round 3, stop looping: note the open findings in the session file `## Notes` and in the PR body for Thomas, and tell the user in plain words that the PR waits for Thomas — don't ping-pong indefinitely.
- Update session round number after each pass so resumption re-enters the loop correctly
