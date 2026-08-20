# `Git::WorktreeInfo` captures the full porcelain record

`Git::Repository#worktrees_all` returns a `[dir, sha]` tuple per worktree, which is
everything the old `Git::Worktree` class needed and much less than
`git worktree list --porcelain` reports. When the worktree API is redesigned around a
value object, `Git::WorktreeInfo` will carry the whole record: `path`, `head`, `branch`,
`bare`, `detached`, `locked` (with its reason), and `prunable` (with its reason).

Widening the record later is not free — it is a second parser change, a second round of
tests, and a second deprecation of whatever narrower shape shipped first. The porcelain
format already gives us the fields, so the only reason to omit them is that no caller
has asked yet, and that reason expires.

`locked` and `prunable` each carry an optional reason string from git, so they are not
plain booleans. Model them so the reason survives.

Relates to issue #1635.
