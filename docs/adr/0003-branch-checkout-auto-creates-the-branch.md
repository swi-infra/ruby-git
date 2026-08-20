# Deprecating `Git::Branch#checkout` must document the auto-create difference

`Git::Branch#checkout` calls `check_if_create` before checking out, so it creates the
branch when it does not exist and swallows any error from that attempt.
`Git::Repository#checkout(name)` does not: checking out a branch that does not exist
fails.

The two are therefore not drop-in replacements, even though every other `Git::Branch`
operation is (see [ADR-0002](0002-git-branch-has-no-capability-gap.md)). A caller who
follows a deprecation warning from `branch('feature').checkout` to
`checkout('feature')` gets a failure the first time the branch is new.

The deprecation warning and the upgrade notes must name this explicitly and point at
the two-call replacement. Silently changing the semantics under a deprecation notice is
worse than not deprecating the method at all, because the warning tells the caller the
migration is safe.

Relates to issue #1639.
