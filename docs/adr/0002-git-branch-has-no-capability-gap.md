# `Git::Branch` has no capability gap

`Git::Branch` can be deprecated without first replicating its behavior elsewhere. An
audit of every operation on the class found that each one already delegates to a
`Git::Repository` facade method that accepts a branch name or any string. Nothing on
`Git::Branch` reaches into git in a way the facade cannot.

Two composites are the exception, and both are convenience wrappers rather than new
capability: `in_branch`, which stashes, checks out, yields, and restores; and the
`merge(branch)` overload that merges the receiver into the current branch. Those are
tracked in issue #1641 as preconditions for the deprecation.

This is recorded because the opposite conclusion is the intuitive one. A class with
twenty methods looks like it must be doing something the facade cannot, and the next
person to look at the deprecation will assume a capability audit is still owed. It is
not — this is it.

Relates to issue #1639.
