---
name: simplifions-work
description: "Take a Linear issue or a bug report of Simplifions to a reviewed pull request: reproduce, challenge, plan, ship, review. Use when the user hands over a ticket (« fais SIM-237 », « prends SIM-237 ») or a bug report, or says go, do it, take care of it."
---

# simplifions-work

The session the user talks to. It gets the Linear issue from the user (§ Linear) or the bug report, decides what needs doing, and does the judgment itself (reproduce, challenge, plan); a subagent does the implementation (ship), which ends on a reviewed pull request. The user is asked product and UX questions only (`CLAUDE.md` § Qui décide quoi). Thomas reviews; the merge follows § Human gates.

## Flow

```
bug report ──> reproduce ──> Linear issue ──> challenge ──> plan ──> user approves ──> ship (subagent) ──> PR reviewed ──> merge
                                                │             │                         │
                                                │             │                         └─ review loop: fresh /simplifions-review, 3 rounds max
                                                │             └─ technical go-ahead needed → comment on the issue for Thomas, stop
                                                └─ RESHAPE / DROP → the user
```

## Routing

| Input | First step | Then |
| --- | --- | --- |
| a bug report: message, screenshot | reproduce it in session, through the app as `/simplifions-verify` drives it | reproduced → issue drafted per [`simplifions-challenge/issue.md`](../simplifions-challenge/issue.md), posted by the user (§ Linear) → challenge; already fixed or not reproduced → the user gets what was tried and seen, stop |
| an issue with no command | `/simplifions-challenge`, in session | `CHALLENGE: GO` → plan; `RESHAPE` or `DROP` → the user |
| an issue with the ask settled | `/simplifions-plan`, in session | plan `ready` → the user approves → ship; questions → § Who decides |
| an approved plan | `/simplifions-ship <ISSUE>`, **one subagent per issue**, in this checkout (no worktree isolation: `.notes/` lives here), prompt exactly `Run /simplifions-ship <ISSUE>` plus the decisions this session holds | PR opened and reviewed inside ship → merge per § Human gates |
| a PR to look at | `/simplifions-review <url>`, fresh subagent | report relayed, in the PR's language |
| a PR of ours Thomas reviewed | one subagent reads his review through GitHub's public API, his comments only (login `Un3x`), each quoted verbatim (WebFetch on `https://api.github.com/repos/datagouv/simplifions/` + `pulls/<n>/reviews`, `pulls/<n>/comments` and `issues/<n>/comments`); each comment not yet fixed on the branch gets its failing test, then its fix with the [red-green-commit](../simplifions-ship/red-green-commit.md) cycle, as a fix-up of the commit it corrects (`/simplifions-commit` step 3) | fixes pushed; a comment left unapplied goes into the PR body with its reason; the PR waits for Thomas's new review, his earlier approval no longer counts; the user told what changed in plain words |
| drift suspected in the feature map | `/simplifions-verify`'s maintain procedure, subagent | outcome told to the user |
| an explicit command | as given | — |

The feature map (`.claude/skills/simplifions-verify/`) is how the agent proves the change to the user and to Thomas: ship drives the feature it touched there, the PR body says in one line what the drive showed, and the evidence path goes only into the report to the user.

## Who decides

`CLAUDE.md` § Qui décide quoi: product and UX questions to the user, technical choices by the rules (`CLAUDE.md`, [`one-rule.md`](../simplifions-plan/one-rule.md)), a remaining technical doubt into the PR body for Thomas. In these skills, « the user » is the person in this session and « Thomas » the technical reviewer.

- **A technical go-ahead** (a new system, a plan `Flag:`, a new file in `app/models/`, a gem, a table, a job, a generic engine — `CLAUDE.md` § Simplicité): a comment asking Thomas, handed to the user to post on the issue (§ Linear), and the work on that issue stops there. The user is told in one sentence that the ticket waits for Thomas.

## Human gates

The session never crosses these on its own: plan approval before ship (shown to the user as the outcome and the acceptance lines in plain words, never the technical steps); `RESHAPE` or `DROP`; anything irreversible (force-push outside the branch's own fix-ups, migration on data, deploy, a message to a partner). It never merges: once Thomas has approved the PR and its full CI is green with no review comment open, it tells the user she can click « Merge pull request » on the PR page, given as its full link (`https://github.com/datagouv/simplifions/pull/<n>`).

## Following a subagent

The Agent tool runs it in the background and notifies on completion; one issue per subagent, at most one subagent that commits at a time (ship, a review's fixes, the feature map's upkeep), since all of them switch this one checkout's branch. On its report: read it, tell the user in one paragraph with the link it gives (the PR page, or the page to open the PR) and the open points, in plain words. A subagent that asks a question the user already settled in this session gets the answer through SendMessage, and the report says what was sent; a product question goes to the user, a technical one follows § Who decides. Cap: 2 h per subagent, then stop and report.

## Linear

The user is the only link to Linear: they read and write it in their browser. Every skill that reads or writes an issue follows this section.

- **Reading an issue**: ask in one line, « Colle-moi le titre, la description et les commentaires utiles de SIM-<n> : https://linear.app/pole-api/issue/SIM-<n> ». Save what they paste, verbatim, to `.notes/sim-<n>-<slug>/issue.md`; plan, ship and review read the issue there, a subagent included. Before a replan of an issue that waits for Thomas, ask the user to paste his answer; it is appended to `issue.md`.
- **Branch and folder**: the branch is `feature/sim-<n>-<slug>`, the folder `.notes/sim-<n>-<slug>/` (found again by `.notes/sim-<n>-*`). The slug is the title in lowercase, accents and apostrophes dropped (« l'équipe » → `lequipe`), every other run of non-letters a `-`, cut at the last whole word within 60 characters: `git branch -r` shows the pattern.
- **Writing to Linear**: hand the user the text in a code block, ready to paste, with the issue link and the place it goes (a comment, the description, a new issue). They post it and say so; the session goes on from there. A subagent puts the text in its report, and this session hands it over. Writing a description or a new issue reads [`simplifions-challenge/issue.md`](../simplifions-challenge/issue.md) first. The hand-offs, all of them:

| When | What the user posts |
| --- | --- |
| a technical go-ahead (§ Who decides), or a design that did not hold in ship | a comment asking Thomas |
| a new issue (a bug reproduced, a challenge with no issue) | the issue; they give back its SIM number, and the draft becomes its `issue.md` |
| a challenge agreed | the issue's new description |
| a challenge disagreed or killed | a comment: the verdict and the user's decision |
| a large PR (`simplifions-commit/review-guide.md`) | the review guide, attached to the issue as a file |

- **Status and PR link**: `Closes <issue URL>` in the PR body; Linear's GitHub integration links the PR and moves the status. No status hand-off.

## Notes folder

Plans, session files and review rounds live in `.notes/` at the repo root, ignored by git. For Thomas it is a symlink to his own notes; for anyone else a plain folder, created on first use (`mkdir -p .notes`). Never commit it.

## Rules

- Judgment in session, implementation in subagents: this session reads app code to reproduce, challenge, plan and review; it does not edit it.
- Every answer sent to a subagent traces to something the user said or a file they validated.
- Nothing secret in a subagent prompt: it lands in the transcript.
- The brief to a subagent is the command plus the decisions of this session, one paragraph; the user does not repeat themselves. An environment workaround a brief carries twice (a variable, a driver, a script that fails) goes once into the feature map or `CLAUDE.local.md`, and leaves the brief.
- This session owns each deliverable from the ask to the merge, and checks it against the ask, not only against the subagent's report.
- When the app, the console, the browser or a logged-in CLI can answer, run it and show the result instead of asking.
