---
name: simplifions-commit
description: "Write a Simplifions commit message, or a pull request title and body, in French, for a reader who has none of the session. Read before every git commit and every gh pr create."
---

# simplifions-commit

The commit is read by the developer in a production incident, from `git blame`, with no ticket open; the PR by its reviewer, Thomas; the issue by a non-technical teammate ([`readers.md`](readers.md)). This repo's own history is the model ([`examples.md`](examples.md)): a subject that names the change in domain words, no body unless a why is not already in the subject, `Closes <link>`. `CLAUDE.md` § Commits and § Pull requests are the repo's rules; this skill is how to meet them.

## Commit message

1. **Subject** — under 60 characters (`CLAUDE.md` § Commits). The behaviour or capability that changed for the site's reader, in French and in domain words, prefixed when it helps by the area in words and a colon: `Carte de vérif : libellés, onglets et listes d'aujourd'hui`. No type prefix (`feat:`, `fix:`). Done when the line reads as a changelog entry for the team.
2. **Body** — empty by default. One or two lines only when the subject leaves a why or a constraint unsaid: the reason, the trap avoided, the situation before. Every sentence carries something the diff cannot show. A sentence that says what the code now does (« le lot transmet maintenant les clés ») is the diff retold: cut it. Lines wrapped at 72 characters. Never the files touched, the steps taken, the plan step, or a ticket link: GitHub resolves the sha to its PR, and the PR carries the issue. Done when nothing in it can be read from the diff.
3. **Fix-ups from a review round** go into the commit they fix: `git commit --fixup <sha>`, then `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main` (no editor opens), pushed with `git push --force-with-lease`. Done when the branch reads as one story, not as the review loop: no « fix suite review », no « WIP », no file added then removed.
4. Commit with the message in a heredoc, no trailer of any kind.

## Pull request

Read [`pull-request.md`](pull-request.md) at `gh pr create`.

## Rules

- The why is written once, in the message: the plan, the issue and the PR are not files the log reader can open.
- The message is in French, whatever language the session runs in.
- A subject past 60 characters is a subject carrying its body: cut it, do not wrap it.
