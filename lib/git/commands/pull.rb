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
    # @example Pull and suppress the merge-commit editor
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', no_edit: true)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-pull/2.53.0
    #
    # @see https://git-scm.com/docs/git-pull git-pull
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Pull < Git::Commands::Base
      arguments do
        literal 'pull'

        # General options
        flag_option %i[quiet q]
        flag_option %i[verbose v]
        flag_or_value_option :recurse_submodules,
                             negatable: true, inline: true

        # Merge options
        flag_option :commit, negatable: true
        flag_option %i[edit e], negatable: true
        value_option :cleanup, inline: true
        flag_option :ff_only
        flag_option :ff, negatable: true
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true
        flag_or_value_option :log, negatable: true, inline: true
        flag_option :signoff, negatable: true
        flag_option :stat
        flag_option %i[no_stat n]
        flag_option :compact_summary
        flag_option :squash, negatable: true
        flag_option :verify, negatable: true
        value_option %i[strategy s], inline: true
        value_option %i[strategy_option X], inline: true, repeatable: true
        flag_option :verify_signatures, negatable: true
        flag_option :summary, negatable: true
        flag_option :autostash, negatable: true
        flag_option :allow_unrelated_histories
        flag_or_value_option %i[rebase r], negatable: true, inline: true

        # Fetch options
        flag_option :all, negatable: true
        flag_option %i[append a]
        flag_option :atomic
        value_option :depth, inline: true
        value_option :deepen, inline: true
        value_option :shallow_since, inline: true
        value_option :shallow_exclude, inline: true, repeatable: true
        flag_option :unshallow
        flag_option :update_shallow
        value_option :negotiation_tip, inline: true, repeatable: true
        flag_option :negotiate_only
        flag_option :dry_run
        flag_option :porcelain
        flag_option %i[force f]
        flag_option %i[keep k]
        flag_option :prefetch
        flag_option %i[prune p]
        flag_option %i[tags t], negatable: true
        value_option :refmap, inline: true, repeatable: true
        value_option %i[jobs j], inline: true
        flag_option :set_upstream
        value_option :upload_pack
        flag_option :progress, negatable: true
        value_option %i[server_option o], inline: true, repeatable: true
        flag_option :show_forced_updates, negatable: true
        flag_option %i[ipv4 4]
        flag_option %i[ipv6 6]

        # Execution options (not emitted as CLI flags)
        execution_option :timeout

        end_of_options
        operand :repository
        operand :refspec, repeatable: true
      end

      # @!method call(*, **)
      #
      #   Execute the `git pull` command
      #
      #   @overload call(repository = nil, *refspecs, **options)
      #
      #     @param repository [String, nil] The remote name or URL to pull from
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
      #     @option options [Boolean, nil] :quiet (nil) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean, nil] :verbose (nil) Enable verbose output during fetch and merge
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String, nil] :recurse_submodules (nil) Control submodule
      #       commit fetching (`--recurse-submodules`)
      #
      #       Pass a string such as `'yes'`, `'on-demand'`, or `'no'` for
      #       `--recurse-submodules=<value>`.
      #
      #     @option options [Boolean, nil] :no_recurse_submodules (nil) Disable submodule
      #       commit fetching (`--no-recurse-submodules`)
      #
      #     @option options [Boolean, nil] :commit (nil) Perform the merge and commit the result
      #       (`--commit`)
      #
      #     @option options [Boolean, nil] :no_commit (nil) Merge but do not commit the result
      #       (`--no-commit`)
      #
      #     @option options [Boolean, nil] :edit (nil) Open an editor for the merge commit message
      #       (`--edit`)
      #
      #       Alias: :e
      #
      #     @option options [Boolean, nil] :no_edit (nil) Do not open an editor for the merge commit
      #       message (`--no-edit`)
      #
      #     @option options [String] :cleanup (nil) Merge-message cleanup mode
      #
      #       Determines how the merge message is cleaned up before committing.
      #       For example, `'strip'`, `'whitespace'`, `'verbatim'`, `'scissors'`, `'default'`.
      #
      #     @option options [Boolean, nil] :ff_only (nil) Require fast-forward merge or up-to-date HEAD
      #
      #       Refuses to merge unless the current HEAD is already up to date or the
      #       merge can be resolved as a fast-forward.
      #
      #     @option options [Boolean, nil] :ff (nil) Allow fast-forward merge (`--ff`)
      #
      #     @option options [Boolean, nil] :no_ff (nil) Disable fast-forward merge, always creating a
      #       merge commit (`--no-ff`)
      #
      #     @option options [Boolean, String, nil] :gpg_sign (nil) GPG-sign the resulting merge commit
      #       (`--gpg-sign`)
      #
      #       Pass a key-ID string to select the signing key. Alias: :S
      #
      #     @option options [Boolean, nil] :no_gpg_sign (nil) Countermand commit.gpgSign configuration
      #       (`--no-gpg-sign`)
      #
      #     @option options [Boolean, Integer, nil] :log (nil) Include one-line descriptions from
      #       the actual commits being merged in log message (`--log`)
      #
      #       Pass an integer for `--log=<n>`.
      #
      #     @option options [Boolean, nil] :no_log (nil) Disable inclusion of one-line descriptions
      #       from merged commits (`--no-log`)
      #
      #     @option options [Boolean, nil] :signoff (nil) Add a `Signed-off-by` trailer to the
      #       resulting merge commit message (`--signoff`)
      #
      #     @option options [Boolean, nil] :no_signoff (nil) Remove a `Signed-off-by` trailer from
      #       the merge commit message (`--no-signoff`)
      #
      #     @option options [Boolean, nil] :stat (nil) Show a diffstat at the end of the merge
      #
      #     @option options [Boolean, nil] :no_stat (nil) Do not show a diffstat at the end of the merge
      #
      #       Alias: :n
      #
      #     @option options [Boolean, nil] :compact_summary (nil) Show a compact summary after the merge
      #
      #     @option options [Boolean, nil] :squash (nil) Squash pulled commits into a single commit
      #       (`--squash`)
      #
      #     @option options [Boolean, nil] :no_squash (nil) Override `--squash` option (`--no-squash`)
      #
      #     @option options [Boolean, nil] :verify (nil) Run pre-merge and commit-msg hooks
      #       (`--verify`)
      #
      #     @option options [Boolean, nil] :no_verify (nil) Bypass pre-merge and commit-msg hooks
      #       (`--no-verify`)
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
      #     @option options [Boolean, nil] :verify_signatures (nil) Verify that the tip commit of
      #       the side branch being merged is signed with a valid key (`--verify-signatures`)
      #
      #     @option options [Boolean, nil] :no_verify_signatures (nil) Do not verify the signature of
      #       the side branch tip commit (`--no-verify-signatures`)
      #
      #     @option options [Boolean, nil] :summary (nil) Show a summary after the merge (`--summary`)
      #
      #     @option options [Boolean, nil] :no_summary (nil) Do not show a summary after the merge
      #       (`--no-summary`)
      #
      #     @option options [Boolean, nil] :autostash (nil) Automatically create a temporary stash entry
      #       before the operation begins (`--autostash`)
      #
      #     @option options [Boolean, nil] :no_autostash (nil) Disable automatic stashing before the
      #       operation (`--no-autostash`)
      #
      #     @option options [Boolean, nil] :allow_unrelated_histories (nil) Allow pulling from a
      #       repository that shares no common history with the current repository
      #
      #     @option options [Boolean, String, nil] :rebase (nil) Rebase the current branch on
      #       top of the upstream branch after fetching (`--rebase`)
      #
      #       Pass a string such as `'merges'` or `'interactive'` for `--rebase=<value>`.
      #       Alias: :r
      #
      #     @option options [Boolean, nil] :no_rebase (nil) Override earlier `--rebase` option
      #       (`--no-rebase`)
      #
      #     @option options [Boolean, nil] :all (nil) Fetch all remotes (`--all`)
      #
      #     @option options [Boolean, nil] :no_all (nil) Do not fetch all remotes (`--no-all`)
      #
      #     @option options [Boolean, nil] :append (nil) Append ref names and object names fetched to
      #       the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean, nil] :atomic (nil) Use an atomic transaction to update local refs
      #
      #     @option options [String] :depth (nil) Limit fetching to the given number of commits
      #
      #       Fetches only the specified number of commits from the tip of each
      #       remote branch history.
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
      #     @option options [Boolean, nil] :unshallow (nil) Convert a shallow repository to a complete one
      #
      #       If the source is shallow, fetches as much as possible.
      #
      #     @option options [Boolean, nil] :update_shallow (nil) Accept refs that update `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) Report only commits
      #       reachable from the given tips during negotiation
      #
      #       Repeatable.
      #
      #     @option options [Boolean, nil] :negotiate_only (nil) Do not fetch; only print ancestries
      #       between the local repository and the remote
      #
      #     @option options [Boolean, nil] :dry_run (nil) Show what would be done without making changes
      #
      #     @option options [Boolean, nil] :porcelain (nil) Give the output in a stable, easy-to-parse
      #       format for scripts
      #
      #     @option options [Boolean, nil] :force (nil) Override the check for a non-fast-forward update
      #
      #       Alias: :f
      #
      #     @option options [Boolean, nil] :keep (nil) Keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean, nil] :prefetch (nil) Modify the configured refspec to place
      #       all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean, nil] :prune (nil) Remove remote-tracking references that no longer
      #       exist on the remote before fetching
      #
      #       Alias: :p
      #
      #     @option options [Boolean, nil] :tags (nil) Fetch all tags from the remote (`--tags`)
      #
      #       Alias: :t
      #
      #     @option options [Boolean, nil] :no_tags (nil) Disable automatic tag following
      #       (`--no-tags`)
      #
      #     @option options [String, Array<String>] :refmap (nil) Override fetch refspecs for
      #       remote-tracking branch mapping
      #
      #       Repeatable.
      #
      #     @option options [String] :jobs (nil) Number of submodules fetched in parallel
      #
      #       Alias: :j
      #
      #     @option options [Boolean, nil] :set_upstream (nil) Add upstream (tracking) reference for
      #       the current branch
      #
      #     @option options [String] :upload_pack (nil) Path to `git-upload-pack` on the remote
      #
      #     @option options [Boolean, nil] :progress (nil) Force progress status display (`--progress`)
      #
      #     @option options [Boolean, nil] :no_progress (nil) Suppress progress status display
      #       (`--no-progress`)
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit the given
      #       string to the server when communicating using protocol version 2
      #
      #       Repeatable. Alias: :o
      #
      #     @option options [Boolean, nil] :show_forced_updates (nil) Check whether a local branch is
      #       force-updated during fetch (`--show-forced-updates`)
      #
      #     @option options [Boolean, nil] :no_show_forced_updates (nil) Disable checking for force
      #       updates (`--no-show-forced-updates`)
      #
      #     @option options [Boolean, nil] :ipv4 (nil) Use IPv4 addresses only, ignoring IPv6 addresses
      #
      #       Alias: :'4'
      #
      #     @option options [Boolean, nil] :ipv6 (nil) Use IPv6 addresses only, ignoring IPv4 addresses
      #
      #       Alias: :'6'
      #
      #     @option options [Numeric, nil] :timeout (nil) Timeout in seconds for the command
      #
      #       If nil, uses the global timeout from {Git::Config}.
      #
      #     @return [Git::CommandLineResult] the result of calling `git pull`
      #
      #     @raise [ArgumentError] if argument validation fails (e.g., unsupported options
      #       are provided or option values are invalid)
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
