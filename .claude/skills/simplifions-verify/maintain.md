# Maintain the map

Read when asked to maintain, check or refresh the feature map, or when a drive fails on a step the app no longer does. The unit is the feature file, not every sentence. The outcome is one of `clean`, `changed`, `blocked`, said in the report.

1. **Index hygiene.** `features/README.md` lists exactly the `.md` files next to it, and each one that is driven has its `.rb` of the same basename; fix missing, dead or duplicate entries.
2. **Source pass.** One read-only subagent per feature file, in parallel: how does this feature work in the source, where does the file drift, one recipe to prove it live. They never drive the app and never edit.
3. **Contract.** Each file keeps the shape of [`feature-file.md`](feature-file.md).
4. **Churn sweep.** Routes, views and JavaScript changed since the map's last commit (`git log --since=<date of the last commit on .claude/skills/simplifions-verify> -- config/routes.rb app/views app/components app/javascript`) with no feature file → candidate files, each with a concrete source path.
5. **Live pass.** Required even when the source looks clean. Launch and doctor (`SKILL.md`), then the whole map (`SKILL.md` § Drive), in Chrome then Firefox; doctor again after any `FAIL`; evidence checked at its path before cleanup. A feature that cannot be reached is `verified-unreachable` only with the concrete prerequisite named; a prerequisite missing from the map is drift.
6. **Triage.** Wrong user-POV description → fix the file. Behaviour the harness cannot drive → fix `harness.rb` or the feature's drive. App actually broken → report it to the user in plain words, keep it out of this change.
7. **Ship.** `changed`: one PR of proven corrections, files under `.claude/skills/simplifions-verify/` only, with the evidence path in its body. `clean` and `blocked` ship nothing.
