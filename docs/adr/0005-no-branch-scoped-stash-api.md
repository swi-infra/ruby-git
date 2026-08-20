# No branch-scoped stash API

Stashes are not branch-scoped in git. They live on the `refs/stash` reflog, one stack
per repository. A stash entry records the branch that was current when it was created,
but that is a label in the entry's message, not an index git can filter on, and popping
a stash onto a different branch is ordinary usage rather than an error.

So ruby-git will not offer `branch.stashes`, `stashes_for(branch)`, or any other API
whose signature implies the stack is partitioned by branch. Filtering entries by the
branch name in their message would be a ruby-git invention wearing a git-shaped name,
and would give a wrong answer for any stash applied across branches.

Recorded as an explicit no because `Git::Branch#stashes` already existed and looked like
the feature (see [ADR-0004](0004-git-branch-stashes-is-deprecate-and-delete.md)), so
removing it reads as a regression unless the reason is written down.
