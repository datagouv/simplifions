---
name: simplifions-review
description: "Paranoid code review of a Simplifions branch, PR, or files: asked versus built, the repo's written rules, four passes, every finding proven. Use whenever the user asks to review a PR, a pull request URL, a branch, or files (\"can you review…\", \"est-ce qu'on peut review…\")."
---

Paranoid code review. It checks what was built against what was asked, checks the diff against the repo's written rules, then runs four passes (critical, informational, design, simplicity). Every finding is proven and ranked by severity. It catches the bugs that pass CI and break in production.

## Usage
- `/simplifions-review`: the current branch against `origin/main`
- `/simplifions-review <PR number or URL>`: a PR (also on a plain request such as « peux-tu review https://github.com/datagouv/simplifions/pull/204 »)
- `/simplifions-review <file1> <file2> ...`: those files

## Steps

1. **Gather the diff.** The session's checkout stays on its branch: `/simplifions-ship` may be working there.
   - No args: `git fetch origin`, note the head SHA (`git rev-parse HEAD`), then `git diff origin/main...<sha>`.
   - PR: `git fetch origin`, then `git fetch origin pull/<n>/head` and note the head SHA (`git rev-parse FETCH_HEAD`). The diff is `git diff origin/main...<sha>`, a file at the head `git show <sha>:<path>`. Read every commit message (`git log --reverse origin/main..<sha>`, then `git show` each past a handful), and the PR body and author on https://github.com/datagouv/simplifions/pull/<n> (WebFetch): they hold the author's why.
   - Files: `git diff origin/main -- <files>`.
   - **Earlier rounds** given in the prompt (`/simplifions-ship`'s loop past round 1): read them, then review only what changed since the `Head:` of the latest one (`git diff <Head>..<sha>`; after a force-push, `git range-diff`). A finding triaged `rebutted` or `deferred` is not raised again; a fixed one is checked as fixed.
2. **Asked versus built**: [`asked.md`](asked.md). Done when every line of the ask carries its mark and the extras are listed.
3. **Drive the change.** When the diff touches routes, views or JavaScript, drive the mapped feature once, in one browser (both browsers are for ship's proof), with the feature map (`.claude/skills/simplifions-verify/`) on the branch's own checkout (no args, or `/simplifions-ship`'s loop) or on a worktree of the PR's branch (`bin/setup_worktree.sh`, then the verify map's first steps); a feature the map does not cover gets a one-off drive (`simplifions-verify` § Drive). Done when the diff touches none of them, the evidence path is on the report's `Drive:` line, or its `Note:` says what the review could not drive: the review's limit, never a gap of the PR. An ask line left undriven stays `delivered` when the code delivers it.
4. **Rules check.** Read [`checklist.md`](checklist.md), then the root [`REVIEW.md`](../../../REVIEW.md) (what failure looks like here, the repo's own checks, what is already known, the paths to skip). Check the diff against every rule of `CLAUDE.md` and `REVIEW.md` whose area it touches. A broken rule is a `rule` row, the rule quoted. Done when every rule touching the diff was checked.
5. **Run the four passes** of the checklist in order: CRITICAL, INFORMATIONAL, DESIGN, SIMPLICITY. Done when every category was checked against the whole diff.
6. **Write the report** in the shape of [`output.md`](output.md), and show it. When the user asks for it on the PR, give the text to paste (`output.md` § To paste on the PR) with the PR's full link; the user posts it.

## Rules

- **Proven or cut.** Every finding has a trace: the entry point that reaches it, the values that get there, the line that misbehaves. A `bug`, `test` or `ask` row ranked critical or important carries a concrete failure scenario (« when X happens, Y breaks because Z »); a `design` row says who holds what. A doubt is investigated, then proven or dropped: no « potential », « may », « risky ». An Unproven premise, or an ask line marked `unclear`, states a missing proof: that is the fact, and it stays.
- **Read before raising.** Read the tests before a `bug` or `test` row: a behaviour a test already pins is not a finding. A choice the PR body or a commit message explains is raised only when the explanation does not hold, quoted in the row.
- **No lint nits**; Pass 2 Readability is not a nit. A clean diff says « ship it ». Clean code that misses a line of the ask is `partial`.
- **One row per class of bug.** Several instances of one kind of bug are one row with its `Class:` and every instance, so one round fixes them all. A bug in code the diff did not change is a `pre-existing` row, left out of the verdict.
- **Who decides** (`CLAUDE.md` § Qui décide quoi): product and UX belong to the product owner. An `ask` row, and any finding about what the visitor sees (a text, a page, a path through the site), ends on the decision she has to make. A technical finding names the rule of `CLAUDE.md` or `REVIEW.md` that settles it, or stands on its proof alone.
