---
name: simplifions-work
description: "Take a Linear issue of Simplifions from the ticket to a reviewed pull request: challenge, plan, ship, review. Use when the user hands over a ticket (« fais SIM-237 », « prends SIM-237 »), or says go, do it, take care of it."
---

# simplifions-work

The session the user talks to. It reads the Linear issue, decides what needs doing, and does the judgment itself (challenge, plan); a subagent does the implementation (ship), which ends on a reviewed pull request. The user is asked product and UX questions only (`CLAUDE.md` § Qui décide quoi). Thomas reviews and merges; no agent ever merges.

## Flow

```
Linear issue ──> challenge ──> plan ──> user approves ──> ship (subagent) ──> PR reviewed ──> Thomas merges
                   │             │                         │
                   │             │                         └─ review loop: fresh /simplifions-review, 3 rounds max
                   │             └─ technical go-ahead needed → comment on the issue for Thomas, stop
                   └─ RESHAPE / DROP → the user
```

## Routing

| Input | First step | Then |
| --- | --- | --- |
| an issue with no command | `/simplifions-challenge`, in session | `CHALLENGE: GO` → plan; `RESHAPE` or `DROP` → the user |
| an issue with the ask settled | `/simplifions-plan`, in session | plan `ready` → the user approves → ship; questions → § Who decides |
| an approved plan | `/simplifions-ship <ISSUE>`, **one subagent per issue**, in this checkout (no worktree isolation: `.notes/` lives here), prompt exactly `Run /simplifions-ship <ISSUE>` plus the decisions this session holds | PR opened and reviewed inside ship → Thomas merges |
| a PR to look at | `/simplifions-review <url>`, fresh subagent | report relayed, in the PR's language |
| an explicit command | as given | — |

The feature map (`.claude/skills/simplifions-verify/`) is how the agent proves the change to the user and to Thomas: ship drives the feature it touched there and the PR cites the evidence.

## Who decides

`CLAUDE.md` § Qui décide quoi: product and UX questions to the user, technical choices by the rules (`CLAUDE.md`, [`one-rule.md`](../simplifions-plan/one-rule.md)), a remaining technical doubt into the PR body for Thomas. In these skills, « the user » is the person in this session and « Thomas » the technical reviewer.

- **A technical go-ahead** (a new system, a plan `Flag:`, a new file in `app/models/`, a gem, a table, a job, a generic engine — `CLAUDE.md` § Simplicité): a comment on the Linear issue asking Thomas, and the work on that issue stops there. The user is told in one sentence that the ticket waits for Thomas.

## Human gates

The session never crosses these on its own: plan approval before ship (shown to the user as the outcome and the acceptance lines in plain words, never the technical steps); merge (Thomas only); `RESHAPE` or `DROP`; anything irreversible (force-push outside the branch's own fix-ups, migration on data, deploy, a message to a partner).

## Following a subagent

The Agent tool runs it in the background and notifies on completion; one issue per subagent, at most one shipping subagent at a time. On its report: read it, tell the user in one paragraph with the PR link and the open points, in plain words. A subagent that asks a question the user already settled in this session gets the answer through SendMessage, and the report says what was sent; a product question goes to the user, a technical one follows § Who decides. Cap: 2 h per subagent, then stop and report.

## Linear

Every skill here reads and writes issues through the Linear MCP tools available in the session, whatever the server is called. None available: `CLAUDE.md` § Début de session says how to connect; until then, ask the user instead of guessing.

| Verb | Call |
| --- | --- |
| read an issue: title, body, status, branch name | `get_issue` (`gitBranchName` is the branch) |
| list a project's open issues | `list_issues` |
| write the description | `save_issue` with `id` and `description` |
| change the status | `save_issue` with `id` and `state` |
| create an issue | `save_issue` without `id` |
| comment | `save_comment` |
| read the comments (Thomas's answer to a go-ahead) | `list_comments` with the issue id |
| attach a file | `prepare_attachment_upload` → `curl -X PUT --data-binary` with the signed headers, within 60 seconds → `create_attachment_from_upload` |
| link a PR | `Closes <issue URL>` in the PR body; Linear's GitHub integration links it |
| is it done? | `get_issue`, status type `completed` or `canceled` |

## Notes folder

Plans, session files and review rounds live in `.notes/` at the repo root, ignored by git. For Thomas it is a symlink to his own notes; for anyone else a plain folder, created on first use (`mkdir -p .notes`). Never commit it.

## Rules

- Judgment in session, implementation in subagents: this session reads app code to challenge, plan and review; it does not edit it.
- Every answer sent to a subagent traces to something the user said or a file they validated.
- Nothing secret in a subagent prompt: it lands in the transcript.
- The brief to a subagent is the command plus the decisions of this session, one paragraph; the user does not repeat themselves.
- When the app, the console, the browser or a logged-in CLI can answer, run it and show the result instead of asking.
