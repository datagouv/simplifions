# The one rule

Read by `/simplifions-plan` before writing a plan, by `/simplifions-ship` when re-planning after a review round, and by `/simplifions-review` (Pass 4 and design reviews). The rungs of `CLAUDE.md` § Simplicité apply first; this page is how a plan meets them.

**The plan is the simplest design that fits what we are building: simple, readable, never over-engineered.**

## What are we building?

Answer first. The kind sets the level of abstraction, the pattern to follow and the expected size. It goes on the plan's `Kind:` line.

| Kind | Shape |
|------|-------|
| **Trivial**: a field, a label, a guard | Inline in the existing code. No new class. |
| **Fills an existing system**: a new page of the catalogue, a new case of a mechanism that already exists | Follow the system's pattern. The new code writes only what is specific to it. If the system has no slot for this case, widening the slot is the work: a refactor first, behaviour unchanged, then the feature. Following the pattern means the same owner, not the same spot: when the new case does not fit where the existing one runs, ask what the code produces (a response, a record, a request) and who owns that, before widening the spot. The existing placement may be the thing to refactor. |
| **A new system**: a mechanism other features will plug into | Name what the next user plugs in, and check it against the next feature of the same kind. The kind goes under Questions (`has-questions`) and the plan stops until Thomas confirms it (a comment on the issue, [`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides)). |
| **Isolated**: a one-off script, an importer, an experiment | Kept apart from the core, simple inside, no reuse expected. |

When the kind is unclear, it is a question, not a guess.

## Rules

- **A graft is not simple.** A small diff that adds a second path for something the system already does (a second builder, a hook beside a chain step, a mock branch beside the real one) is wrong even when it works. Widen the existing path instead. A second path the design grid finds, new or already there, is never accepted as is: the plan removes it, or proposes the preparatory change that removes it under Questions.
- **Vanilla Rails first.** Reach for the Rails built-in (`validates`, `normalizes`, `enum`, scopes, `delegated_type`, `generates_token_for`, Turbo, …) before any custom construct, config flag or option hash.
- **Code goes with the object that owns the decision**, in its existing home when one fits. Read every user of that home first: an object shared by two entry points cannot own behaviour that belongs to one of them. An entry point that skips the behaviour through a guard or an early return is still a user: the guard is the sign of a wrong owner, never the reason to dismiss it.
- **Name a class like the other classes of its role in this app** (component, interactor, organizer…): look at how they are named before naming a new or moved one. A `BuildX` interactor that becomes a plain object producing an artifact is `XBuilder`, not bare `X`.
- **A new class, layer or abstraction needs a reason from the kind**: a slot of a system, a third use, or a mechanism it removes (name it). Generic machinery with a single user is over-engineering.
- **Thomas drives escalation.** If you believe the shape the kind calls for is insufficient, or the preparatory refactor outweighs the feature, add **one flagged sentence** at the end of the plan (« Flag: I think X because Y »), mark the issue `has-questions` in the plan session file, ask Thomas in a comment on the issue, and stop. Never design the alternative.
