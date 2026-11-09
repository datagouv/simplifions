# Pull request title and body

Read before opening a pull request, and at `/simplifions-ship`'s prove-and-push phase. The reader is the reviewer, Thomas, then the developer who lands here from a commit months later when the issue is archived ([`readers.md`](readers.md)): the why must stand without Linear. In French.

- **One PR = one functionality**, self-sufficient and usable on its own once merged: a reader must not need another PR to understand it, and merging it must leave the site with something usable. Size is not a reason to split; unreadability is a reason to guide.
- **Title**: the story of the branch in under 60 characters, shaped like a commit subject. A one-commit PR takes its commit subject verbatim.
- **Body**, this shape and nothing else:

  ```
  <one to three lines: what the reader gets, and the one constraint or trade-off they must know — the technical choice made and the doubt left for Thomas, from the plan's « For the reviewer »>

  Closes <issue URL>
  ```
  Under `Closes`, when the change is user-facing, one line says what the feature-map drive showed: the action, the result seen and, when short, the text read back, so the reviewer starts from a proof instead of redoing it. Never a local path (`tmp/verify/…`): the reviewer cannot open it, and it is gone with the worktree. The `Closes` line becomes `Suite de`, `Related` or a sha for a follow-up without an issue. A screenshot when the change is visible, attached as § Opening it says. Numbered steps to test by hand only when the diff does not make them obvious. The commits are the reading path: when their order matters, one line says « à lire commit par commit » with the first one to open; when the PR outgrows that read, one line above `Closes` points to the review guide ([`review-guide.md`](review-guide.md)).
- Nothing else: no headers, no test plan (CI and the diff), no proof essay (21 lines of `git grep` to prove a field was dead, when the two specs pinning it were the proof), no restating of the issue.
- **Opening it**, once the review loop is done (`/simplifions-ship` opens it at its hand over): `git push -u origin <branch>`, then:
  - **`gh auth status` says logged in**: the agent opens the PR, `gh pr create --repo datagouv/simplifions --base main --title <title> --body-file <file holding the body>`, its screenshot attached with the `gh-image` skill. Done when the user has the PR's link.
  - **Otherwise**: hand the user https://github.com/datagouv/simplifions/compare/<branch>?expand=1 with the title and the body, each in its own code block, ready to paste; the user drops the screenshot into the body on the GitHub page. Done when the user has the link and both blocks.
- Review replies and follow-ups: assistants post on PR threads only what the PR needs and the user cannot see otherwise: the PR itself (§ Opening it) and the review's captures ([`simplifions-review` § Captures on the PR](../simplifions-review/output.md#captures-on-the-pr)); the merge follows [`simplifions-work` § Human gates](../simplifions-work/SKILL.md#human-gates). A follow-up that changes the scope goes to the user as a question; a technical leftover goes into the PR body for Thomas; Thomas talks to the team.
