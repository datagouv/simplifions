# Design grid

Read by `/simplifions-review` Passes 3 and 4 on the diff, and by `/simplifions-plan` on the draft plan before it is marked `ready`.

Before walking the grid, read what the change plugs into: base classes, callers, every other user of the classes it touches, how the same problem is solved elsewhere in the repository. An object shared by two entry points changes where a responsibility can live.

Report only what the code shows. An empty family is a fine outcome.

## Responsibilities

- **Misplaced rule** (tell, don't ask): a caller decides something the object could state itself.
- **Re-derived knowledge**: a layer rebuilds from an output (a message, a title, a serialized payload, a raw header) what another layer knew as a typed fact. Stringly typed, it breaks silently when the wording changes.
- **Ad-hoc list**: ask what justifies « this case yes, that one no ». No business rule behind it: the list is the smell. A rule behind it: the rule goes in the code, not the list. Before tagging cases one by one, ask whether an existing type already states the rule: then the rule follows the type, and a case that disagrees has the wrong type. An HTTP status is not such a type: a rule keyed on it is a **Misplaced rule**.
- **Wrong owner for the entry point**: behaviour of one route, caller or response in an object several routes share.
- **Reaching through objects**: reading another object's internals or options instead of asking it.
- **Stretched inheritance**: refused bequest, a base built for another case, constants borrowed from a sibling.
- **Two classes in one**: most methods of a class open on the same branch. It holds two objects: split them and pick one where it is built.

## Control flow

- **Fighting the framework**: a hook wrapping a chain, rescue and re-raise, `send` on a private method, because the natural seam does not fit. The code sits in the wrong place.
- **Graft** (`simplifions-plan/one-rule.md`): a second path beside the one that already does the job: a second builder, a hook beside a chain step, a mock, test or feature-flag path re-implementing the real path's decision.
- **Exceptions as control flow**, and broad rescues that turn a bug into a log line.
- **Partial writes**: an object or context mutated step by step, so a failure midway needs cleanup. Compute first, write once.

## State and data

- **Shared mutable context**: values set then reset to hide them, defensive copies, temporal coupling.
- **Inputs mutated in place** (normalization, defaults), so the original is lost to whoever needs it later. Parse at the boundary into a new value.
- **Time**: several « now » in one operation, time zones, expiry windows.
- **Cache**: does the new behaviour bypass, poison or leak through a cache, and on which key. A cached value whose content, shape or lifetime changes gets a new key in the same commit, not a purge left to the deploy.
- **Environment branches** in production code.

## Contracts

- **Public contract**: URLs, the sitemaps, the shape of what other sites or crawlers read. A change in a shared parent class reaches every subclass's output: check it for each, or move it down to the subclass.
- **Overspecified tests and docs**: they encode a sorting rule, not a need, and flip the day the rule changes.

## Simplicity

Complexity that costs more than it pays, against `simplifions-plan/one-rule.md`. Each finding states its deletion payoff (« inlining this removes 40 lines and one file »). A construct the plan names as removing a mechanism (a graft, a list, a copy) is neither single-caller indirection nor a wrong level of abstraction. A Readability rewrite (`checklist.md` Pass 2) is never a finding here.

- **Kind mismatch**: the shape does not match the kind (`one-rule.md` § What are we building), as a system built for a field or a guard, or a graft where an existing system needed widening.
- **Wrong level of abstraction**: speculative generality (params, options, flags or branches nothing uses today), a new class or module where existing code had a natural home, or a copy of an existing variant where the system already has a seam for it. Check with the deletion test, and ask what the next feature of the same kind would have to write.
- **Breaks convention over configuration**: config flags, option hashes, initializers or custom plumbing where a Rails convention or built-in does the job: name the built-in.
- **Single-caller indirection**: a class, service or method with exactly one call site that could be inlined (a `build_x` behind an `@x ||=` memo, or a `shared_examples`, is readability, not indirection).
- **Impossible-state defense**: guards and rescues for states the actual callers cannot produce.
- **Plan drift** (on a diff only): a diff much larger than the plan's size estimate (`.notes/<branch>/plan.md`): name where it grew. Lines added by a readability rewrite are not drift.

## Product and security

- **What the feature lets a user prove, forge, skip or learn**: a draft reached before « Publier », a response revealing whether a record exists.
- **Personal data**: minimization, who sees what.
- **Invented value**: a missing value replaced by a default the code cannot know is right, in a param or on a page. Unknown is written as unknown, or the call fails fast.
