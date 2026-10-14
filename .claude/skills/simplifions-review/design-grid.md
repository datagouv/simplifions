# Design grid

Read by `/simplifions-review` Pass 3 on the diff, and by `/simplifions-plan` on the draft plan before it is marked `ready`. Adapted from the design pass of a teammate's review skill (skelz0r/dotfiles, `manual-review-pr` §4), which produced the Apistration PR #500 review.

Before walking the grid, read what the change plugs into: base classes, callers, every other user of the classes it touches, how the same problem is solved elsewhere in the repository. An object shared by two entry points changes where a responsibility can live.

Report only what the code shows. An empty family is a fine outcome.

## Responsibilities

- **Misplaced rule**: a caller decides something the object could state itself. A `case` or a table on error types to know which deserve a proof, instead of each error saying so.
- **Re-derived knowledge**: a layer rebuilds from an output (a message, a title, a serialized payload, a raw header) what another layer knew as a typed fact. Matching on human-readable strings breaks silently when the wording changes.
- **Ad-hoc list**: ask what justifies « this case yes, that one no ». No business rule behind it: the list is the smell. A rule behind it: the rule goes in the code, not the list. Before tagging cases one by one, ask whether an existing type or status already states the rule (a 404 already means « definitive, no result »): then the rule follows the type, and a case that disagrees has the wrong type.
- **Wrong owner for the entry point**: behaviour that depends on the route, the caller or the response placed in an object several routes share.
- **Reaching through objects**: reading another object's internals or options instead of asking it.
- **Stretched inheritance**: a subclass overriding a base method to disable it, a base built for another case, constants borrowed from a sibling.
- **Layer direction** (Rails): a model reading `Current` or the request, a service taking `params`, a controller computing a business rule, a view querying the database, a mailer sent from a model callback.
- **Wrong level of abstraction**: generic machinery with a single user, or a copy of an existing variant where the system already has a slot for it. Ask what the next feature of the same kind would have to write.

## Control flow

- **Working around the framework**: a hook wrapping a chain, rescue and re-raise, `send` on a private method, because the natural extension point does not fit. The code sits in the wrong place.
- **Two mechanisms for one thing**: a feature adds a second path next to the one that already does the job (a second builder, a hook beside a chain step).
- **Exceptions as control flow**, and broad rescues that turn a bug into a log line.
- **Partial writes**: an object or context mutated step by step, so a failure midway needs cleanup. Compute first, write once.

## State and data

- **Shared mutable context**: values set then reset to hide them, defensive copies, reads that depend on step order.
- **Inputs mutated in place** (normalization, defaults), so the original is lost to whoever needs it later. Capture it at the boundary.
- **Time**: several « now » in one operation, time zones, expiry windows.
- **Cache**: does the new behaviour bypass, poison or leak through a cache, and on which key.

## Paths and environments

- **Duplicated paths**: mock, sandbox, test or feature-flag paths that re-implement the real path's decision and can drift from it.
- **Environment branches** in production code.

## Contracts

- **Public contract**: response shape, error format, SDKs, generated docs, compatibility for existing clients.
- **Tests and docs encoding a sorting rule** rather than a need: they flip the day the rule changes.

## Product and security

- **What the feature lets a user prove, forge, skip or learn**: a document obtained with chosen inputs, a response revealing whether a record exists.
- **Personal data**: minimization, who sees what.
