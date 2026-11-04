# Who reads what

Each artefact has one reader, and its length is what that reader has time for.

| Artefact | Reader | When | They need | Goal | Links to |
| --- | --- | --- | --- | --- | --- |
| Commit | the developer in a production incident, from `git blame` / `git log -S`; the PR reviewer second | 2 am, no ticket open | what changed, in a word they can grep; the why when the subject cannot carry it | [`SKILL.md`](SKILL.md) steps 1 and 2 | nothing: GitHub resolves the sha to its PR |
| Pull request | the reviewer; the same developer six months later, when the issue is archived | opening the diff, then the commits in order | one functionality, self-sufficient; the high-level why and the one constraint; how to test only when it is not obvious from the diff | 1 to 3 lines + `Closes`; a review guide when the commits alone cannot carry the read | the Linear issue, for the whole story; the guide for a large PR |
| Issue body | a non-technical teammate, the founder, the sub-assistant | deciding, prioritising, briefing | why, scope, what it will not do — in plain words a twelve-year-old follows | one screen | the PR once it exists |
| Issue comment | the same readers, in a thread | a scope question needs an answer | one question, open or closed, whose answer splits, merges or bounds the issue; or the answer | a few lines | — |
| Plan | Thomas, the coding agent | before and during `/simplifions-ship` | the steps, the diagram, the size cap | as long as it needs | stays in `.notes/`; its « For the reviewer » items reach the PR body |

What does not go on Linear: shipping logs, review rounds, rebase notes, file counts, class names, and the plan. The issue's readers asked for none of it. The technical how lives in the code, which is meant to read at a glance.
