# C1c-2 Audit: `Git::Base` → `Git::Repository` Inventory

**Date:** 2026-06-06
**Branch:** `agents/c1c2-audit-inventory-documentation`
**Produced by:** Step C1c-2 (research-and-documentation only; no production code changed)

This document is the exhaustive public-method inventory required before any
remediation work (PR 2–4) begins. Every public instance method on `Git::Base`
is compared against `Git::Repository`, and every orphaned public method on
`Git::Lib` that would silently break when `Git::Lib` is removed in Phase 4 is
surfaced.

---

## 1. Summary Counts

| Bucket | ✅ | ⬜ | ❌ | ⚠️ | 🔍 | Total |
|--------|----|----|----|----|-----|-------|
| 1 — Path/accessors | 4 | 0 | 0 | 0 | 0 | 4 |
| 2 — Compatibility aliases & wrappers | 1 | 3 | 4 | 0 | 0 | 8 |
| 3 — Low-level public methods | 0 | 6 | 0 | 0 | 1 | 7 |
| 4 — Factory & domain-object returns | 12 | 0 | 0 | 0 | 0 | 12 |
| 5 — Keyword-arg signature review | 3 | 0 | 0 | 5 | 2 | 10 |
| 6 — `Git::Lib` orphaned public methods | — | — | — | — | — | **⚠️ see §6** |
| **Grand total (Buckets 1–5)** | **20** | **9** | **4** | **5** | **3** | **41** |

> ⚠️ **Bucket 6 contains more than 40 genuine orphaned public methods**
> (see §6 for the full count breakdown). Per the audit instructions, this
> section recommends splitting the Bucket 6 promotion work into a companion
> document rather than embedding it in the remediation PRs.

---

## 2. Full Inventory Table

Sorted by bucket, then alphabetically within bucket.

| Method | Bucket | Status | Destination / Notes |
|--------|--------|--------|---------------------|
| `dir` | 1 | ✅ | `Git::Repository#dir` (repository.rb:89) |
| `index` | 1 | ✅ | `Git::Repository#index` (repository.rb:113) |
| `repo` | 1 | ✅ | `Git::Repository#repo` (repository.rb:101) |
| `repo_size` | 1 | ✅ | `Git::Repository#repo_size` (repository.rb:131) |
| `checkout` | 2 | ✅ | `Git::Repository::Branching#checkout` |
| `diff_name_status` | 2 | ⬜ | Alias for `diff_path_status`; add alias to `Git::Repository::Diffing` |
| `remove` | 2 | ⬜ | Alias for `rm`; add alias to `Git::Repository::Staging` |
| `revparse` | 2 | ⬜ | Alias for `rev_parse`; add alias to `Git::Repository::ObjectOperations` |
| `is_branch?` | 2 | ❌ | Already deprecated in `Git::Base`; emit deprecation only |
| `is_local_branch?` | 2 | ❌ | Already deprecated in `Git::Base`; emit deprecation only |
| `is_remote_branch?` | 2 | ❌ | Already deprecated in `Git::Base`; emit deprecation only |
| `reset_hard` | 2 | ❌ | Already deprecated in `Git::Base`; emit deprecation only |
| `apply` | 3 | ⬜ | New facade in `Git::Repository::Staging` (or new `Patching` module); `Git::Commands::Apply` ✅ |
| `apply_mail` | 3 | ⬜ | Same module as `apply`; `Git::Commands::Am` ✅ |
| `describe` | 3 | ⬜ | New facade in `Git::Repository::Inspecting`; `Git::Commands::Describe` ✅ |
| `gc` | 3 | ⬜ | New facade in new `Git::Repository::Maintenance`; `Git::Commands::Gc` ✅ |
| `read_tree` | 3 | ⬜ | New facade in `Git::Repository::Staging` (already owns index ops); `Git::Commands::ReadTree` ✅ |
| `repack` | 3 | ⬜ | New facade in new `Git::Repository::Maintenance`; `Git::Commands::Repack` ✅ |
| `cat_file` | 3 | 🔍 | `Git::Base#cat_file` delegates to `lib.cat_file` which **does not exist** in `Git::Lib`; the method is silently broken; `Git::Repository::ObjectOperations#cat_file_contents` is the likely intended replacement — see §6 |
| `add_tag` | 4 | ✅ | `Git::Repository::ObjectOperations#add_tag` |
| `branch` | 4 | ✅ | `Git::Repository::Branching#branch` |
| `branches` | 4 | ✅ | `Git::Repository::Branching#branches` |
| `delete_tag` | 4 | ✅ | `Git::Repository::ObjectOperations#delete_tag` |
| `gblob` | 4 | ✅ | `Git::Repository::ObjectOperations#gblob` |
| `gcommit` | 4 | ✅ | `Git::Repository::ObjectOperations#gcommit` |
| `gtree` | 4 | ✅ | `Git::Repository::ObjectOperations#gtree` |
| `object` | 4 | ✅ | `Git::Repository::ObjectOperations#object` |
| `remote` | 4 | ✅ | `Git::Repository::RemoteOperations#remote` |
| `remotes` | 4 | ✅ | `Git::Repository::RemoteOperations#remotes` |
| `tag` | 4 | ✅ | `Git::Repository::ObjectOperations#tag` — returns `Git::Object::Tag` ✅ |
| `tags` | 4 | ✅ | `Git::Repository::ObjectOperations#tags` — returns `Array<Git::Object::Tag>` ✅ |
| `add` | 5 | ⚠️ | Staging#add: `(paths = '.', **)` → should be `(paths = '.', opts = {})` |
| `branch_delete` | 5 | 🔍 | Branching#branch_delete: `(*branches, **options)` — lib.rb also uses `**options`; needs explicit classification |
| `commit` | 5 | ⚠️ | Committing#commit: `(message = nil, **opts)` → should be `(message, opts = {})` |
| `commit_all` | 5 | ⚠️ | Committing#commit_all: `(*, **)` → should be `(message, opts = {})` |
| `commit_tree` | 5 | ⚠️ | Committing#commit_tree: `(tree, **opts)` → should be `(tree = nil, opts = {})` |
| `fsck` | 5 | 🔍 | Inspecting#fsck: `(*objects, **)` vs base.rb `(*objects, **opts)` — both already use kwargs; functionally equivalent but `**` is anonymous; needs explicit classification |
| `reset` | 5 | ⚠️ | Staging#reset: `(commitish = nil, **)` → should be `(commitish = nil, opts = {})` |
| `write_and_commit_tree` | 5 | ✅ | Committing#write_and_commit_tree: `(**)` — 5.x-native (no legacy predecessor in `Git::Base`) |
| `checkout_file` | 5 | ✅ | Branching#checkout_file: `(version, file)` — matches `Git::Base` signature ✅ |
| `revert` | 5 | ✅ | Merging#revert: `(commitish = nil, opts = {})` — matches `Git::Base` signature ✅ |

---

## 3. ⬜ Migration Candidates

### Bucket 2

#### `remove`

**Current implementation:** `Git::Base` line 420 — `alias remove rm`.
**Proposed destination:** `Git::Repository::Staging` — add `alias remove rm` after the `rm` method.
**Classification:** `legacy-contract` — 4.x public API alias.
**Effort:** trivial (one-line alias).

#### `revparse`

**Current implementation:** `Git::Base` line 879 — `alias revparse rev_parse`.
**Proposed destination:** `Git::Repository::ObjectOperations` — add `alias revparse rev_parse`.
**Classification:** `legacy-contract` — widely used 4.x shorthand.
**Effort:** trivial (one-line alias).

#### `diff_name_status`

**Current implementation:** `Git::Base` line 1198 — `alias diff_name_status diff_path_status`.
**Proposed destination:** `Git::Repository::Diffing` — add `alias diff_name_status diff_path_status`.
**Classification:** `legacy-contract` — 4.x public API alias.
**Effort:** trivial (one-line alias).

### Bucket 3

#### `describe`

**Current implementation:** `Git::Base#describe(committish = nil, opts = {})` (base.rb:466) → `lib.describe(committish, opts)`. `Git::Lib#describe` (lib.rb:223) → `Git::Commands::Describe.new(self).call(...)`. `Git::Commands::Describe` ✅ exists.
**Proposed destination:** `Git::Repository::Inspecting` — already houses `show` and `fsck`; `describe` is a read-only inspection operation.
**Classification:** `legacy-contract` — preserve `(commit_ish = nil, opts = {})` exactly.
**Effort:** moderate — needs option allowlist cross-referenced against 4.x `*_OPTION_MAP`; the `exact-match` → `exact_match` key translation currently in `Git::Lib#describe` must be preserved in the facade.

#### `gc`

**Current implementation:** `Git::Base#gc` (base.rb:699) → `lib.gc`. `Git::Lib#gc` (lib.rb:1778) → `Git::Commands::Gc.new(self).call(prune: true, aggressive: true, auto: true)`. `Git::Commands::Gc` ✅ exists.
**Proposed destination:** New `Git::Repository::Maintenance` topic module (pair with `repack`). Alternatively `Git::Repository::Inspecting` if a new module is not justified.
**Classification:** `legacy-contract` — preserve `()` (no arguments).
**Effort:** trivial — zero-arity facade; fixed options forwarded to command class.

#### `repack`

**Current implementation:** `Git::Base#repack` (base.rb:695) → `lib.repack`. `Git::Lib#repack` (lib.rb:1774) → `Git::Commands::Repack.new(self).call(a: true, d: true)`. `Git::Commands::Repack` ✅ exists.
**Proposed destination:** New `Git::Repository::Maintenance` topic module (pair with `gc`).
**Classification:** `legacy-contract` — preserve `()` (no arguments).
**Effort:** trivial — zero-arity facade; fixed options forwarded to command class.

#### `apply`

**Current implementation:** `Git::Base#apply(file)` (base.rb:754) — applies patch only when `File.exist?(file)`; delegates to `lib.apply(file)`. `Git::Lib#apply` (lib.rb:1248) → `Git::Commands::Apply.new(self).call(...)`. `Git::Commands::Apply` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — already owns low-level index operations; `apply` is a patch-application operation closely related to staging.
**Classification:** `legacy-contract` — preserve `(file)` signature and the `File.exist?` guard in `Git::Base`.
**Effort:** moderate — must preserve the `File.exist?` guard and the `chdir: @git_work_dir` execution option.

#### `apply_mail`

**Current implementation:** `Git::Base#apply_mail(file)` (base.rb:760) — applies `git am` only when `File.exist?(file)`; delegates to `lib.apply_mail(file)`. `Git::Lib#apply_mail` (lib.rb:1252) → `Git::Commands::Am::Apply.new(self).call(...)`. `Git::Commands::Am` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — alongside `apply`.
**Classification:** `legacy-contract` — preserve `(file)` signature and the `File.exist?` guard.
**Effort:** moderate — same concerns as `apply`.

#### `read_tree`

**Current implementation:** `Git::Base#read_tree(treeish, opts = {})` (base.rb:813) → `lib.read_tree(treeish, opts)`. `Git::Lib#read_tree` (lib.rb:1798) → `Git::Commands::ReadTree.new(self).call(...)`. `Git::Commands::ReadTree` ✅ exists.
**Proposed destination:** `Git::Repository::Staging` — already owns `checkout_index`, `write_tree`, etc.
**Classification:** `legacy-contract` — preserve `(treeish, opts = {})`.
**Effort:** trivial — thin orchestration; the option allowlist (`:prefix`) is already defined in `Git::Lib::READ_TREE_ALLOWED_OPTS`.

---

## 4. ❌ Intentional Removals

### `reset_hard`

**Rationale:** Already deprecated in `Git::Base` (base.rb:431–438) with a `Git::Deprecation.warn` call directing callers to `reset(commitish, hard: true)`.
**Upgrade path:** Use `Git::Base#reset(commitish, hard: true)` instead.
**`@deprecated` tag:** The method body contains `Git::Deprecation.warn` but no YARD `@deprecated` tag is present — a YARD `@deprecated` tag should be added before Phase 4.

### `is_local_branch?`

**Rationale:** Already deprecated in `Git::Base` (base.rb:299–305) directing callers to `local_branch?`.
**Upgrade path:** Use `Git::Base#local_branch?(branch)` instead.
**`@deprecated` tag:** Runtime deprecation is present; YARD `@deprecated` tag is missing — should be added.

### `is_remote_branch?`

**Rationale:** Already deprecated in `Git::Base` (base.rb:312–318) directing callers to `remote_branch?`.
**Upgrade path:** Use `Git::Base#remote_branch?(branch)` instead.
**`@deprecated` tag:** Runtime deprecation present; YARD `@deprecated` tag missing — should be added.

### `is_branch?`

**Rationale:** Already deprecated in `Git::Base` (base.rb:325–331) directing callers to `branch?`.
**Upgrade path:** Use `Git::Base#branch?(branch)` instead.
**`@deprecated` tag:** Runtime deprecation present; YARD `@deprecated` tag missing — should be added.

---

## 5. ⚠️ Signature Gaps

All five gaps are `legacy-contract` violations: the facade method uses `**opts`
or `**` keyword-splat where the 4.x predecessor used a positional `opts = {}`
hash. In Ruby 3, passing a bare `Hash` variable as the last positional argument
to a `**`-accepting method raises `ArgumentError`, silently breaking callers who
do `repo.add('file', my_opts_hash)`.

### `Git::Repository::Staging#add`

**Current signature:** `add(paths = '.', **)` (staging.rb:55)
**Corrected signature:** `add(paths = '.', opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1 — `legacy-contract` methods must copy the 4.x call shape verbatim. `Git::Base#add` and `Git::Lib#add` both used positional `options = {}`.
**Action:** Change `**)` to `opts = {})` in the method signature and update internal delegation accordingly.

### `Git::Repository::Staging#reset`

**Current signature:** `reset(commitish = nil, **)` (staging.rb:88)
**Corrected signature:** `reset(commitish = nil, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#reset` used positional `opts = {}`.
**Action:** Change `**)` to `opts = {})`.

### `Git::Repository::Committing#commit`

**Current signature:** `commit(message = nil, **opts)` (committing.rb:77)
**Corrected signature:** `commit(message, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit` used `(message, opts = {})` — `message` is required. The facade also relaxed `message` to optional, which is a silent API drift.
**Action:** Remove default from `message`; change `**opts` to `opts = {}`.

### `Git::Repository::Committing#commit_all`

**Current signature:** `commit_all(*, **)` (committing.rb:110)
**Corrected signature:** `commit_all(message, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit_all` used `(message, opts = {})`. The current splatted form accepts anything and makes the public contract invisible.
**Action:** Restore explicit positional parameters.

### `Git::Repository::Committing#commit_tree`

**Current signature:** `commit_tree(tree, **opts)` (committing.rb:147)
**Corrected signature:** `commit_tree(tree = nil, opts = {})` (legacy-contract)
**C1c-1 rule violated:** Rule 1. `Git::Base#commit_tree` used `(tree = nil, opts = {})` — `tree` is optional in the legacy API.
**Action:** Add default `= nil` to `tree`; change `**opts` to `opts = {}`.

---

## 6. 🔍 Human Decisions Needed

### `cat_file` (Bucket 3)

**Background:** `Git::Base#cat_file(objectish)` (base.rb:925) delegates to `lib.cat_file(objectish)`. However, **`Git::Lib` contains no `cat_file` method**. The method is effectively broken at runtime (calling it raises `NoMethodError`). `Git::Repository::ObjectOperations` provides `cat_file_contents(object)` which returns the raw content of a git object — the most plausible intended behavior.

**Specific question:** Should `cat_file` be:

**Option A — Alias for `cat_file_contents`:** Add `alias cat_file cat_file_contents` to `Git::Repository::ObjectOperations` and wire `Git::Base#cat_file` to delegate there. Preserves a broken API under a new implementation.

**Option B — Deprecated stub:** Add a `@deprecated` tag to `Git::Base#cat_file` directing callers to `cat_file_contents`, emit a `Git::Deprecation.warn`, and do not promote it to `Git::Repository`. The method was silently broken; promoting it may confuse callers who never successfully used it.

**Option C — Silent removal:** Remove `Git::Base#cat_file` in v5 with an upgrade note. It was broken in the current codebase and therefore has no legitimate callers.

**Recommended default if no human input:** Option B — issue a deprecation warning and point to `cat_file_contents`, which is the clear successor.

---

### `branch_delete` (Bucket 5)

**Background:** `Git::Repository::Branching#branch_delete(*branches, **options)` uses keyword-arg splat. `Git::Lib#branch_delete(*branches, **options)` also uses `**options`. There is no `Git::Base#branch_delete` delegator (the method is not publicly accessible via `g.branch_delete` — it is a Bucket 6 orphan exposed only via `g.lib.branch_delete`). Because there is no 4.x `Git::Base` predecessor with a `opts = {}` signature, the `legacy-contract` rule may not apply.

**Specific question:** Should `branch_delete` be classified as:

**Option A — `5.x-native`:** The method was added to `Git::Lib` with keyword args and was never part of the public `Git::Base` surface. The `**options` signature in `Git::Repository` is therefore correct and intentional. Document as `5.x-native`.

**Option B — `legacy-contract` with signature fix:** Treat `Git::Lib#branch_delete` as the public contract source (Pattern B) and require the `Git::Repository` facade to mirror `(*branches, **options)` exactly. No change needed — the signatures already match.

**Option C — `legacy-contract` with reversion to `opts = {}`:** Revert to a positional options hash for consistency with other methods. This would break any callers already using `branch_delete` with keyword args.

**Recommended default if no human input:** Option A or B — both are acceptable since the lib.rb signature already uses keyword args. Option A is cleaner because it gives `5.x-native` status.

---

### `fsck` (Bucket 5)

**Background:** `Git::Base#fsck(*objects, **opts)` (base.rb:749) and `Git::Repository::Inspecting#fsck(*objects, **)` (inspecting.rb:146) both accept keyword args. The only difference is anonymous `**` vs named `**opts`. For external callers the behavior is identical. However, the named form `**opts` is more conventional and matches the base.rb signature.

**Specific question:** Should `fsck` be:

**Option A — `legacy-contract` with minor fix:** Change `**` to `**opts` in the facade signature for clarity and consistency. Functionally equivalent; cosmetic improvement.

**Option B — `5.x-native`:** `fsck` was migrated early and the `**` anonymous form was intentional per the facade-implementation conventions. Classify as `5.x-native` and leave the signature as-is.

**Recommended default if no human input:** Option A — the named `**opts` is more readable and matches the base.rb public contract. The change is purely cosmetic.

---

## 7. Bucket 6 — `Git::Lib` Orphaned Public Methods

> ⚠️ **SIZE WARNING:** This bucket contains **more than 40 genuine orphaned
> public methods**. Per the audit instructions this warrants a companion
> document. **Recommendation: do not embed the full Bucket 6 remediation in
> PR 2–4. Create a separate document `redesign/c1c2_bucket6_lib_orphans.md`
> and address promotions in a dedicated PR 5.**

The subsections below provide a high-level triage. The companion document
should contain the full per-method analysis.

### 7.1 Scope

`Git::Lib` is declared `@api private` but `Git::Base#lib` is a public accessor,
making every public method on `Git::Lib` reachable as `g.lib.method_name`. When
`Git::Lib` is deleted in Phase 4, all such call sites silently break.

The criterion for inclusion in this bucket:
- Public instance method in `lib/git/lib.rb` (i.e., appears before `private` at line 2200)
- **No same-named delegator on `Git::Base`** (methods already covered by a
  `Git::Base` wrapper appear in Buckets 1–5)

### 7.2 Methods Already Migrated to `Git::Repository` (trivial base.rb wiring needed)

These orphans exist on `Git::Lib` and have already been migrated to a
`Git::Repository` module. The remediation is a trivial one-line delegator in
`Git::Base`. They should be batched into PR 2 or a separate lightweight PR.

| `Git::Lib` method | `Git::Repository` home | Status |
|-------------------|------------------------|--------|
| `branches_all` | `Git::Repository::Branching` | ⬜ promote — add `Git::Base` delegator |
| `branch_contains(commit, branch_name = '')` | `Git::Repository::Branching` | ⬜ promote — add `Git::Base` delegator |
| `branch_delete(*branches, **options)` | `Git::Repository::Branching` | ⬜ promote — add `Git::Base` delegator (see §6 classification note) |
| `branch_new(branch, start_point = nil, options = {})` | `Git::Repository::Branching` | ⬜ promote — add `Git::Base` delegator |
| `cat_file_commit(object)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `cat_file_contents(object)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `cat_file_size(object)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `cat_file_tag(object)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `cat_file_type(object)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `config_remote(name)` | `Git::Repository::RemoteOperations` | ⬜ promote — add `Git::Base` delegator |
| `diff_index(treeish)` | `Git::Repository::Diffing` | ⬜ promote — add `Git::Base` delegator |
| `full_tree(sha)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `name_rev(commit_ish)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `stash_apply(id = nil)` | `Git::Repository::Stashing` | ⬜ promote — add `Git::Base` delegator |
| `stash_clear` | `Git::Repository::Stashing` | ⬜ promote — add `Git::Base` delegator |
| `stash_save(message)` | `Git::Repository::Stashing` | ⬜ promote — add `Git::Base` delegator |
| `stashes_all` | `Git::Repository::Stashing` | ⬜ promote — add `Git::Base` delegator |
| `tag_sha(tag_name)` | `Git::Repository::ObjectOperations` | ⬜ promote — add `Git::Base` delegator |
| `untracked_files` | `Git::Repository::StatusOperations` | ⬜ promote — add `Git::Base` delegator |
| `worktree_add(dir, commitish = nil)` | `Git::Repository::WorktreeOperations` | ⬜ promote — add `Git::Base` delegator |
| `worktree_prune` | `Git::Repository::WorktreeOperations` | ⬜ promote — add `Git::Base` delegator |
| `worktree_remove(dir)` | `Git::Repository::WorktreeOperations` | ⬜ promote — add `Git::Base` delegator |
| `worktrees_all` | `Git::Repository::WorktreeOperations` | ⬜ promote — add `Git::Base` delegator |

Also note name-mismatch cases where `Git::Lib` uses a different name than `Git::Repository`:

| `Git::Lib` method | `Git::Repository` equivalent | Action |
|-------------------|-------------------------------|--------|
| `conflicts` (yields file, your, their) | `Git::Repository::Merging#each_conflict` | 🔍 `conflicts` yields tempfiles; `each_conflict` does too — verify behavioral equivalence |
| `empty?` | `Git::Repository::StatusOperations#no_commits?` | 🔍 keep `empty?` as a deprecated alias on `Git::Base`, pointing to `no_commits?` |
| `remote_add(name, url, opts)` | `Git::Repository::RemoteOperations#add_remote` | 🔍 name mismatch; `add_remote` is already on `Git::Base` — `remote_add` is the lib name; mark as internal |
| `remote_remove(name)` | `Git::Repository::RemoteOperations#remove_remote` | 🔍 name mismatch; `remove_remote` is already on `Git::Base` |
| `remote_set_url(name, url, opts)` | `Git::Repository::RemoteOperations#set_remote_url` | 🔍 name mismatch; `set_remote_url` is already on `Git::Base` |
| `namerev` (alias for `name_rev`) | `Git::Repository::ObjectOperations#name_rev` | ⬜ add `alias namerev name_rev` to `ObjectOperations` |
| `object_contents` (alias for `cat_file_contents`) | `Git::Repository::ObjectOperations#cat_file_contents` | ⬜ add alias to `ObjectOperations` |
| `object_type` (alias for `cat_file_type`) | `Git::Repository::ObjectOperations#cat_file_type` | ⬜ add alias to `ObjectOperations` |
| `object_size` (alias for `cat_file_size`) | `Git::Repository::ObjectOperations#cat_file_size` | ⬜ add alias to `ObjectOperations` |
| `commit_data` (alias for `cat_file_commit`) | `Git::Repository::ObjectOperations#cat_file_commit` | ⬜ add alias to `ObjectOperations` |
| `tag_data` (alias for `cat_file_tag`) | `Git::Repository::ObjectOperations#cat_file_tag` | ⬜ add alias to `ObjectOperations` |
| `revparse` (alias for `rev_parse`) | (covered in Bucket 2) | ✅ covered |

### 7.3 Methods NOT Yet in `Git::Repository` (new facade work required)

These require a new facade method before a base.rb delegator can be added.

| `Git::Lib` method | Assessment | Recommended status |
|-------------------|------------|--------------------|
| `branch_current` | Returns current branch name or 'HEAD' — equivalent to `Git::Repository::Branching#current_branch`. No new facade needed; just add delegator to `Git::Base` pointing to `current_branch`. | ⬜ promote (trivial) |
| `change_head_branch(branch_name)` | Low-level `git symbolic-ref HEAD refs/heads/<name>`; used internally for branch renaming and orphan checkout. Plausible external use by tooling. | 🔍 human decision — promote to `Git::Repository::Branching` or mark as internal? |
| `config_get(name)` | Returns a single config value. Used by tooling. Part of the existing `config()` facade which reads/writes. | 🔍 human decision — expose as `config_get` or fold into `config(name)`? |
| `config_list` | Returns full config hash. Used by tooling. | 🔍 human decision — expose separately or fold into `config()`? |
| `config_set(name, value, options)` | Sets a config value. | 🔍 human decision — expose separately or fold into `config(name, value)`? |
| `global_config_get(name)` | Gets a global config value. | 🔍 human decision |
| `global_config_list` | Returns the full global config hash. | 🔍 human decision |
| `global_config_set(name, value)` | Sets a global config value. | 🔍 human decision |
| `git_version` | Returns `Git::Version` for the current binary. Useful for tooling that conditionally enables features. | ⬜ promote — add to a suitable module (e.g., `Git::Repository::Inspecting` or a new `VersionHelpers` module); moderate effort |
| `list_files(ref_dir)` | Lists files under `.git/refs/{ref_dir}`. Internal ref-filesystem access. No plausible clean public use. | ❌ remove — internal plumbing; direct callers should migrate to `Git::Repository` ref-inspection methods |
| `ls_remote(location = nil, opts = {})` | Lists remote refs. Clearly useful externally. | ⬜ promote — new facade in `Git::Repository::RemoteOperations`; `Git::Commands::LsRemote` ✅ exists; moderate effort |
| `mv(source, destination, options = {})` | Wraps `git mv`. Externally useful. | ⬜ promote — new facade in `Git::Repository::Staging`; `Git::Commands::Mv` ✅ exists; trivial effort |
| `parse_config(file)` | Parses a config file from path. | 🔍 human decision — expose or fold into `config()` with `:file` option? |
| `stash_list` | Returns a formatted string `"stash@{0}: ...\n..."` — distinct from `stashes_all` which returns structured data. | 🔍 human decision — promote for backward compat, or deprecate in favor of `stashes_all`? |
| `unmerged` | Returns paths with unresolved merge conflicts. Already partially covered by `each_conflict` (yields tempfiles). Pure path list is useful. | 🔍 human decision — promote `unmerged` as a simpler alternative to `each_conflict`? |
| `current_branch_state` | Returns a `HeadState` struct with `:state` (`:active`/`:unborn`/`:detached`) and `:name`. Richer than `current_branch`. | ⬜ promote — add to `Git::Repository::Branching`; trivial effort (command class already wired in lib.rb) |

### 7.4 Internal Plumbing — Mark as ❌ Remove

These methods are technically public (defined before `private` in lib.rb) but are
clearly internal helpers with no plausible external use. They should appear in the
upgrade notes as "unsupported; remove any `g.lib.X` calls."

| Method | Reason |
|--------|--------|
| `assert_args_are_not_options(arg_name, *args)` | Input validation helper |
| `assert_valid_opts(opts, allowed)` | Option validation helper |
| `cat_file_object_meta(object)` | Internal batch cat-file helper |
| `command_capturing(*, **options_hash)` | Low-level command execution infrastructure |
| `command_streaming(*, **options_hash)` | Low-level command execution infrastructure |
| `each_cat_file_header(data)` | Parsing helper |
| `handle_deprecated_path_option(opts)` | Deprecation handling helper |
| `normalize_pathspecs(pathspecs, arg_name)` | Input normalization helper |
| `parse_cat_file_meta(output, object)` | Parsing helper |
| `parse_config_list(lines)` | Internal config parsing helper |
| `process_commit_data(data, sha)` | Parsing helper (used by `cat_file_commit`) |
| `validate_pathspec_types(pathspecs, arg_name)` | Input validation helper |

### 7.5 Bucket 6 Count Summary

| Status | Count |
|--------|-------|
| ⬜ promote (repo already has it, trivial base.rb wiring) | 23 |
| ⬜ promote (new facade work required) | 7 |
| ❌ remove (internal plumbing) | 12 |
| 🔍 human decision | 16 |
| **Total orphaned methods** | **58** |

> **Recommendation:** The 23 "trivial wiring" promotions can be handled in PR 5a
> as a batch. The 7 "new facade" promotions and 16 human-decision items should be
> addressed in a companion document (`redesign/c1c2_bucket6_lib_orphans.md`)
> before PR 5b begins.

---

## 8. Recommended PR Split for Remediation

### PR 2 — Aliases / Wrappers (Bucket 2 + Bucket 6 trivial wiring)

**Scope:**
- Add aliases `remove`, `revparse`, `diff_name_status` to the corresponding
  `Git::Repository` modules (3 trivial changes).
- Add YARD `@deprecated` tags to `reset_hard`, `is_local_branch?`,
  `is_remote_branch?`, `is_branch?` in `Git::Base` (4 YARD-only changes).
- Batch-add `Git::Base` delegators for the 23 Bucket 6 "trivial wiring" orphans
  from §7.2 that already have a `Git::Repository` home.
- Add legacy aliases to `Git::Repository::ObjectOperations` for `namerev`,
  `object_contents`, `object_type`, `object_size`, `commit_data`, `tag_data`.

**Dependency:** None — can be merged first.

**Effort:** Small (mostly one-line additions, no new command classes or parsers).

### PR 3 — Low-Level Methods (Bucket 3)

**Scope:**
- Implement facade methods for `describe`, `repack`, `gc`, `apply`, `apply_mail`,
  `read_tree` in `Git::Repository`.
- Create a new `Git::Repository::Maintenance` module for `repack` and `gc`.
- Add `Git::Base` delegators for all six methods.
- Resolve `cat_file` per the human decision in §6.
- Add facade methods for `mv`, `ls_remote`, `git_version`, `current_branch_state`
  from Bucket 6 §7.3 (new facade work needed).

**Dependency:** PR 3 is independent of PR 2 but should be merged after PR 2
to keep the base.rb delegator surface tidy.

**Effort:** Moderate (6 facade methods + 4 new bucket-6 facades + optional new module).

### PR 4 — Signature Sweep (Bucket 5)

**Scope:**
- Fix 5 `⚠️` signatures: `add`, `reset`, `commit`, `commit_all`, `commit_tree`
  in `Git::Repository` modules.
- Resolve human decisions for `branch_delete` and `fsck` classifications.

**Dependency:** PR 4 can be merged in any order relative to PR 2 and PR 3,
**but must be merged before** `Git.open`/`.clone`/`.init`/`.bare` are changed
to return `Git::Repository` directly — the signature fixes are required to
prevent Ruby 3 `ArgumentError` regressions for callers passing hash variables.

**Effort:** Small (signature changes only; no new logic). Tests for the
legacy call shapes (positional hash) must be added or verified.

### PR 5 — Bucket 6 Companion Document + Remaining Promotions

**Scope:**
- Author `redesign/c1c2_bucket6_lib_orphans.md` to capture the full Bucket 6
  analysis for the 16 human-decision items and the 7 new-facade-required items.
- Implement the 7 new facade promotions once human decisions are resolved.
- Mark the 12 internal plumbing methods as `@api private` or move them behind
  `private` in `Git::Lib` as a preparatory step for Phase 4 deletion.

**Dependency:** PR 5 depends on PR 2 (trivial wiring PR sets the delegation
baseline), and on the companion document review for the 16 human-decision items.

**Effort:** Moderate-to-large; primarily gated on human decisions.

### Dependency Graph

```
PR 2 (aliases + trivial wiring)
  └─→ PR 3 (low-level facades) ──┐
  └─→ PR 4 (signature sweep) ────┤──→ Phase C1d (switch Git.open to return Git::Repository)
PR 5 (bucket-6 companion + new facades) (can proceed in parallel with PR 3/4)
```

No circular dependencies. PR 2 unblocks everything else and should be merged
first.
