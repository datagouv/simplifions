# The one rule

The rungs of `CLAUDE.md` § Simplicité apply first; this page is how a plan meets them.

**The plan is the simplest design that fits what we are building: simple, readable, never over-engineered.**

## What are we building?

Answer first. The kind sets the level of abstraction, the pattern to follow and the expected size. It goes on the plan's `Kind:` line.

| Kind | Shape |
|------|-------|
| **Fills an existing system**: a field, a label, a guard, a new page of the catalogue, a new case of a mechanism that already exists | Follow the system's pattern. The new code writes only what is specific to it; a field, a label or a guard stays in the existing code, no new class. If the system has no slot for this case, widening it is the work: preparatory refactoring, then the feature. Following the pattern means the same owner, not the same spot: when the new case does not fit where the existing one runs, ask what the code produces (a response, a record, a request) and who owns that, before widening the spot. The existing placement may be the thing to refactor. |
| **A new system**: a mechanism other features will plug into | Name the slot the next feature plugs into and check it against the next feature of the same kind. The kind goes under Questions (`has-questions`) and the plan stops until Thomas confirms it (a comment on the issue, [`simplifions-work` § Who decides](../simplifions-work/SKILL.md#who-decides)). |
| **Isolated**: a one-off script, an importer, an experiment | Kept apart from the core, simple inside, no reuse expected. |

When the kind is unclear, it is a question, not a guess.

## Rules

- **A graft is not simple.** A graft is a second path for something the system already does (a second builder, a hook beside a chain step, a mock branch beside the real one), wrong even when it works. Widen the existing path. The plan removes a graft the design grid finds, new or old, or puts the preparatory refactoring that removes it under Questions.
- **Vanilla Rails first.** Reach for the Rails built-in (`validates`, `normalizes`, `enum`, scopes, `delegated_type`, `generates_token_for`, Turbo, …) before any custom construct, config flag or option hash.
- **Code goes with the object that owns the decision**, in its existing home when one fits. Read every user of that home first: an object shared by two entry points cannot own behaviour that belongs to one of them. An entry point that skips the behaviour through a guard or an early return is still a user: the guard is the sign of a wrong owner, never the reason to dismiss it.
- **Name a class like the other classes of its role in this app** (component, interactor, organizer…): look at how they are named before naming a new or moved one. A `BuildX` interactor that becomes a plain object producing an artifact is `XBuilder`, not bare `X`.
- **A new class, layer or abstraction needs a reason**: a slot of the system, the rule of three, or a mechanism it removes (name it). Generic machinery with a single user is speculative generality.
- **Thomas drives escalation.** If you believe the shape the kind calls for is insufficient, or the preparatory refactoring outweighs the feature, add **one flagged sentence** at the end of the plan (« Flag: I think X because Y »), ask Thomas in a comment on the issue, and stop. Never design the alternative.
