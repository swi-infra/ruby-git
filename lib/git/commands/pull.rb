# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git pull` command
    #
    # Incorporates changes from a remote repository into the current branch.
    # In its default mode, `git pull` is shorthand for `git fetch` followed
    # by `git merge FETCH_HEAD`.
    #
    # @see https://git-scm.com/docs/git-pull git-pull documentation
    #
    # @api private
    #
    # @example Pull from the default remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call
    #
    # @example Pull from a named remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin')
    #
    # @example Pull a specific branch from a remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', 'main')
    #
    # @example Pull with rebase instead of merge
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', rebase: true)
    #
    # @example Pull with allow-unrelated-histories
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', 'feature', allow_unrelated_histories: true)
    #
    class Pull < Git::Commands::Base
      arguments do
        literal 'pull'
        # Always suppress editor for non-interactive use
        literal '--no-edit'

        # General options
        flag_option %i[quiet q]                                           # --quiet; alias: :q
        flag_option %i[verbose v]                                         # --verbose; alias: :v
        flag_option :progress                                             # --progress
        flag_or_value_option :recurse_submodules, # --[no-]recurse-submodules[=yes|on-demand|no]
                             negatable: true, inline: true

        # Merge behavior
        flag_option :commit, negatable: true                              # --commit / --no-commit
        value_option :cleanup, inline: true                               # --cleanup=<mode>
        flag_option :ff, negatable: true                                  # --ff / --no-ff
        flag_option :ff_only                                              # --ff-only
        flag_or_value_option :log, negatable: true, inline: true          # --log[=<n>] / --no-log
        flag_option :squash, negatable: true                              # --squash / --no-squash
        flag_option :verify, negatable: true                              # --verify / --no-verify
        value_option %i[strategy s]                                       # -s <strategy>; alias: :s
        value_option %i[strategy_option X], repeatable: true # -X <option>; alias: :X
        flag_option :verify_signatures, negatable: true                   # --verify-signatures / --no-verify-signatures
        flag_option :summary, negatable: true                             # --summary / --no-summary
        flag_option :allow_unrelated_histories                            # --allow-unrelated-histories
        flag_or_value_option %i[rebase r], negatable: true, inline: true # --rebase[=<mode>] / --no-rebase; alias: :r
        flag_option :autostash, negatable: true                           # --autostash / --no-autostash
        flag_option :signoff, negatable: true                             # --signoff / --no-signoff
        flag_option :stat                                                 # --stat
        flag_option %i[no_stat n]                                         # --no-stat; alias: :n
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true # -S[<key>] / --no-gpg-sign; alias: :S

        # Fetch-related options
        flag_option :all                                                  # --all
        flag_option %i[append a]                                          # --append; alias: :a
        flag_option :atomic                                               # --atomic
        value_option :depth                                               # --depth <n>
        value_option :deepen                                              # --deepen <n>
        value_option :shallow_since, inline: true                         # --shallow-since=<date>
        value_option :shallow_exclude, inline: true, repeatable: true     # --shallow-exclude=<ref>
        flag_option :unshallow                                            # --unshallow
        flag_option :update_shallow                                       # --update-shallow
        value_option :negotiation_tip, inline: true, repeatable: true # --negotiation-tip=<commit|glob>
        flag_option :negotiate_only                                       # --negotiate-only
        flag_option :dry_run                                              # --dry-run
        flag_option :prefetch                                             # --prefetch
        flag_option %i[force f]                                           # --force; alias: :f
        flag_option %i[keep k]                                            # --keep; alias: :k
        flag_option %i[prune p]                                           # --prune; alias: :p
        flag_option %i[tags t], negatable: true                           # --tags / --no-tags; alias: :t
        value_option %i[jobs j]                                           # --jobs=<n>; alias: :j
        flag_option :set_upstream                                         # --set-upstream
        value_option :upload_pack                                         # --upload-pack=<path>
        value_option %i[server_option o], inline: true, repeatable: true  # --server-option=<option>; alias: :o
        flag_option :show_forced_updates, negatable: true # --show-forced-updates / --no-show-forced-updates
        value_option :refmap, inline: true, repeatable: true # --refmap=<refspec>
        flag_option :ipv4                                                 # --ipv4
        flag_option :ipv6                                                 # --ipv6

        # Execution options (not emitted as CLI flags)
        execution_option :timeout

        end_of_options
        operand :repository                                               # [<repository>]
        operand :refspecs, repeatable: true                               # [<refspec>…]
      end

      # @!method call(*, **)
      #
      #   Execute the git pull command
      #
      #   @overload call(repository = nil, *refspecs, **options)
      #
      #     @param repository [String, nil] (nil) The remote name or URL to pull from
      #
      #       When nil, git uses the default remote for the current branch.
      #
      #     @param refspecs [Array<String>] Zero or more refspecs specifying which refs to fetch
      #       and merge
      #
      #       Each may be a branch name or refspec pattern.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :quiet (nil) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :verbose (nil) Pass `--verbose` to git fetch and merge
      #
      #       Alias: :v
      #
      #     @option options [Boolean] :progress (nil) Force progress reporting even if stderr
      #       is not a terminal
      #
      #     @option options [Boolean, String, nil] :recurse_submodules (nil) Control submodule
      #       commit fetching
      #
      #       `true` for `--recurse-submodules`, `false` for `--no-recurse-submodules`,
      #       or a string such as `'yes'`, `'on-demand'`, `'no'` for
      #       `--recurse-submodules=<value>`.
      #
      #     @option options [Boolean] :commit (nil) Perform the merge and commit the result
      #
      #       `true` for `--commit`, `false` for `--no-commit`.
      #
      #     @option options [String] :cleanup (nil) Determine how the merge message for creating
      #       a merge commit is cleaned up before committing
      #
      #       For example, `'strip'`, `'whitespace'`, `'verbatim'`, `'scissors'`, `'default'`.
      #
      #     @option options [Boolean] :ff (nil) Control whether fast-forward is allowed
      #
      #       `true` for `--ff`, `false` for `--no-ff`.
      #
      #     @option options [Boolean] :ff_only (nil) Refuse to merge unless the current HEAD
      #       is already up to date or the merge can be resolved as a fast-forward
      #
      #     @option options [Boolean, Integer] :log (nil) Include one-line descriptions from
      #       the actual commits being merged in log message
      #
      #       `true` for `--log`, `false` for `--no-log`, or an integer for `--log=<n>`.
      #
      #     @option options [Boolean] :squash (nil) Squash all commits from the pulled branch
      #       into a single commit on top of the current branch
      #
      #       `true` for `--squash`, `false` for `--no-squash`.
      #
      #     @option options [Boolean] :verify (nil) Run pre-merge and commit-msg hooks
      #
      #       `true` for `--verify`, `false` for `--no-verify`.
      #
      #     @option options [String] :strategy (nil) Use the given merge strategy
      #
      #       For example, `'ort'`, `'recursive'`, `'resolve'`, `'octopus'`, `'ours'`, `'subtree'`.
      #       Alias: :s
      #
      #     @option options [String, Array<String>] :strategy_option (nil) Pass option(s) to
      #       the merge strategy
      #
      #       Can be a single value or array. For example, `'ours'`, `'theirs'`, `'patience'`.
      #       Alias: :X
      #
      #     @option options [Boolean] :verify_signatures (nil) Verify that the tip commit of
      #       the side branch being merged is signed with a valid key
      #
      #       `true` for `--verify-signatures`, `false` for `--no-verify-signatures`.
      #
      #     @option options [Boolean] :summary (nil) Control whether to show a summary after
      #       the merge
      #
      #       `true` for `--summary`, `false` for `--no-summary`.
      #
      #     @option options [Boolean] :allow_unrelated_histories (nil) Allow pulling from a
      #       repository that shares no common history with the current repository
      #
      #     @option options [Boolean, String, nil] :rebase (nil) Rebase the current branch on
      #       top of the upstream branch after fetching
      #
      #       `true` for `--rebase`, `false` for `--no-rebase`, or a string such as `'merges'`
      #       or `'interactive'` for `--rebase=<value>`. Alias: :r
      #
      #     @option options [Boolean] :autostash (nil) Automatically create a temporary stash entry
      #       before the operation begins
      #
      #       `true` for `--autostash`, `false` for `--no-autostash`.
      #
      #     @option options [Boolean] :signoff (nil) Add a `Signed-off-by` trailer to the
      #       resulting merge commit message
      #
      #       `true` for `--signoff`, `false` for `--no-signoff`.
      #
      #     @option options [Boolean] :stat (nil) Show a diffstat at the end of the merge
      #
      #     @option options [Boolean] :no_stat (nil) Do not show a diffstat at the end of the merge
      #
      #       Alias: :n
      #
      #     @option options [Boolean, String, nil] :gpg_sign (nil) GPG-sign the resulting merge commit
      #
      #       `true` for `--gpg-sign`, a String key ID for `--gpg-sign=<keyid>`, `false` for
      #       `--no-gpg-sign`. Alias: :S
      #
      #     @option options [Boolean] :all (nil) Fetch all remotes
      #
      #     @option options [Boolean] :append (nil) Append ref names and object names fetched to
      #       the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :atomic (nil) Use an atomic transaction to update local refs
      #
      #     @option options [String] :depth (nil) Limit fetching to the specified number of commits
      #       from the tip of each remote branch history
      #
      #     @option options [String] :deepen (nil) Deepen or shorten history of a shallow repository
      #
      #     @option options [String] :shallow_since (nil) Deepen or shorten history to include all
      #       reachable commits after the given date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) Exclude commits reachable
      #       from the specified remote branch or tag
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :unshallow (nil) Convert a shallow repository to a complete one,
      #       or fetch as much as possible from a shallow source
      #
      #     @option options [Boolean] :update_shallow (nil) Accept refs that update `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) Report only commits
      #       reachable from the given tips during negotiation
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :negotiate_only (nil) Do not fetch; only print ancestries
      #       between the local repository and the remote
      #
      #     @option options [Boolean] :dry_run (nil) Show what would be done without making changes
      #
      #     @option options [Boolean] :prefetch (nil) Modify the configured refspec to place
      #       all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean] :force (nil) Override the check for a non-fast-forward update
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :keep (nil) Keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :prune (nil) Remove remote-tracking references that no longer
      #       exist on the remote before fetching
      #
      #       Alias: :p
      #
      #     @option options [Boolean, nil] :tags (nil) Control tag fetching behavior
      #
      #       `true` for `--tags` (fetch all tags), `false` for `--no-tags` (disable
      #       automatic tag following). Alias: :t
      #
      #     @option options [String] :jobs (nil) Number of submodules fetched in parallel
      #
      #       Alias: :j
      #
      #     @option options [Boolean] :set_upstream (nil) Add upstream (tracking) reference for
      #       the current branch
      #
      #     @option options [String] :upload_pack (nil) Path to `git-upload-pack` on the remote
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit the given
      #       string to the server when communicating using protocol version 2
      #
      #       Repeatable. Alias: :o
      #
      #     @option options [Boolean] :show_forced_updates (nil) Control display of forced updates
      #
      #       `true` for `--show-forced-updates`, `false` for `--no-show-forced-updates`.
      #
      #     @option options [String, Array<String>] :refmap (nil) Use this refspec to map the
      #       refs to remote-tracking branches, instead of the fetch refspecs
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :ipv4 (nil) Use IPv4 addresses only, ignoring IPv6 addresses
      #
      #     @option options [Boolean] :ipv6 (nil) Use IPv6 addresses only, ignoring IPv4 addresses
      #
      #     @option options [Integer] :timeout (nil) Timeout in seconds for the command
      #
      #     @return [Git::CommandLineResult] the result of calling `git pull`
      #
      #     @raise [Git::FailedError] if the pull fails
    end
  end
end
