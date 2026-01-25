# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Stash changes in the working directory
      #
      # Saves local modifications to a new stash entry and rolls them back
      # to HEAD (in the working tree and index). The command takes
      # various options to customize what gets stashed.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Save all changes with a message
      #   Git::Commands::Stash::Push.new(context).call(message: 'WIP: feature work')
      #
      # @example Stash only specific files
      #   Git::Commands::Stash::Push.new(context).call('src/file.rb', message: 'Partial stash')
      #
      # @example Keep staged changes in index
      #   Git::Commands::Stash::Push.new(context).call(keep_index: true)
      #
      # @example Include untracked files
      #   Git::Commands::Stash::Push.new(context).call(include_untracked: true)
      #
      class Push
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          flag %i[patch p], args: '--patch'
          flag %i[staged S], args: '--staged'
          negatable_flag %i[keep_index k], args: '--keep-index'
          flag %i[include_untracked u], args: '--include-untracked'
          flag %i[all a], args: '--all'
          flag %i[quiet q], args: '--quiet'
          inline_value %i[message m], args: '--message'
          inline_value :pathspec_from_file, args: '--pathspec-from-file'
          flag :pathspec_file_nul, args: '--pathspec-file-nul'
          positional :pathspecs, variadic: true, separator: '--'
        end.freeze

        # Creates a new Push command instance
        #
        # @param context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(context)
          @context = context
        end

        # Stash changes in the working directory
        #
        # @overload call(*pathspecs, **options)
        #
        #   @param pathspecs [Array<String>] optional paths to limit what gets stashed
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :message (nil) descriptive message for the stash.
        #     Alias: :m
        #
        #   @option options [Boolean] :patch (nil) interactively select hunks to stash.
        #     Alias: :p
        #
        #   @option options [Boolean] :staged (nil) stash only staged changes.
        #     Alias: :S
        #
        #   @option options [Boolean, nil] :keep_index (nil) keep staged changes in index;
        #     true adds --keep-index, false adds --no-keep-index, nil omits the flag.
        #     Alias: :k
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #     Alias: :u
        #
        #   @option options [Boolean] :all (nil) include untracked and ignored files.
        #     Alias: :a
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        #   @option options [String] :pathspec_from_file (nil) read pathspecs from file
        #
        #   @option options [Boolean] :pathspec_file_nul (nil) pathspecs are NUL separated
        #
        # @return [String] the command output
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @context.command('stash', 'push', *args)
        end
      end
    end
  end
end
