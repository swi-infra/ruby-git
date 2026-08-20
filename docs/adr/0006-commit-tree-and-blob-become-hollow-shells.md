# `Git::Object::Commit`, `Tree`, and `Blob` become hollow shells, not removals

The other ActiveRecord-style classes in the gem are on an additive-then-deprecate path:
introduce an immutable `*Info` value object, move callers to it, deprecate the old class
in one major, remove it in the next. `Git::Object::Commit`, `Git::Object::Tree`, and
`Git::Object::Blob` are deliberately exempt from the removal half.

Instead: introduce `CommitInfo`, `TreeInfo`, `TreeEntryInfo`, and `BlobInfo` along with
typed facade methods that return them, then reimplement the existing classes on top of
those. One implementation, two public shapes, no removal scheduled.

Two reasons.

`log.first.message` and `repo.gcommit(sha).author` are among the most-used idioms in the
gem. Breaking them buys internal tidiness at a cost paid by nearly every downstream
project, and the AR-style shape is not itself a defect once the duplicated implementation
behind it is gone.

Blobs cannot be value objects at all. Blob content is unbounded — a value object would
have to read the whole thing eagerly to construct itself. `Git::Object::Blob` is a lazy
handle, and that laziness is the feature. `BlobInfo` can carry the metadata (sha, size,
mode, path); it cannot carry the contents, so it cannot replace the handle.

## Consequences

Issue #1636 currently schedules these classes for eventual removal and is wrong; it needs
updating to match this decision.

The guardrail from the migration plan still applies: do not add *new* public APIs that
return AR-style objects. This ADR keeps the existing ones working, it does not license
more of them.
