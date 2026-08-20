# `Git::Branch#stashes` is deprecate-and-delete, not migrate

`Git::Branch#stashes` returns `Git::Stashes.new(branch_repository)` — every stash in
the repository, with the branch receiver ignored entirely. Calling
`repo.branch('feature').stashes` and `repo.branch('main').stashes` gives the same
answer.

So there is no branch-scoped behavior to preserve. The method is removed rather than
reimplemented on top of a value object, and callers are pointed at
`Git::Repository#stashes_all`, which is what they were already getting.

The alternative — building a real branch-scoped implementation and calling it a fix —
is rejected because git has no such concept to implement against; see
[ADR-0005](0005-no-branch-scoped-stash-api.md).

Relates to issue #1637.
