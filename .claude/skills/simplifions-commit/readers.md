# Who reads what

Read from `/simplifions-commit` step 1, from `/simplifions-ship` phase 2 and 4, and from any session that writes on an issue. Each artefact has one reader, and its length is what that reader has time for.

| Artefact | Reader | When | They need | Cap | Links to |
| --- | --- | --- | --- | --- | --- |
| Commit | the developer in a production incident, from `git blame` / `git log -S`; the PR reviewer second | 2 am, no ticket open | what changed, in a word they can grep; the why when the subject cannot carry it | subject ≤ 60 ch, body only what the diff cannot show, wrapped at 72 | nothing: GitHub resolves the sha to its PR |
| Pull request | the reviewer; the same developer six months later, when the issue is archived | opening the diff, then the commits in order | one functionality, self-sufficient; the high-level why and the one constraint; how to test only when it is not obvious from the diff | 1 to 3 lines + `Closes`; a review guide when the commits alone cannot carry the read | the Linear issue, for the whole story; the guide for a large PR |
| Issue body | a non-technical teammate, the founder, the sub-assistant | deciding, prioritising, briefing | why, scope, what it will not do — in plain words a twelve-year-old follows | one screen | the PR once it exists |
| Issue comment | the same readers, in a thread | a scope question needs an answer | one question, open or closed, whose answer splits, merges or bounds the issue; or the answer | a few lines | — |
| Plan | Thomas, the coding agent | before and during `/simplifions-ship` | the steps, the diagram, the size cap | as long as it needs | attached to the issue as a file, never as a comment |

What does not go on Linear: plans, shipping logs, review rounds, rebase notes, file counts, class names. Bangun CRE-278 (2026-09-24 → 25) carried four comments and 9 000 characters of that, for one reader who asked for none of it. The technical how lives in the code, which is meant to read at a glance; the plan is a file on the issue for whoever wants the detail.
