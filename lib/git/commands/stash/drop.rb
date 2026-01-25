# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Remove a stash entry from the stash list
      #
      # Removes a single stash entry from the list of stash entries.
      # If no stash reference is given, it removes the latest one.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Drop the latest stash
      #   Git::Commands::Stash::Drop.new(context).call
      #
      # @example Drop a specific stash
      #   Git::Commands::Stash::Drop.new(context).call('stash@{2}')
      #
      class Drop
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          flag %i[quiet q], args: '--quiet'
          positional :stash
        end.freeze

        # Creates a new Drop command instance
        #
        # @param context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(context)
          @context = context
        end

        # Drop a stash entry
        #
        # @overload call(**options)
        #
        #   Drop the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        # @overload call(stash, **options)
        #
        #   Drop a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        # @return [String] the command output
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @context.command('stash', 'drop', *args)
        end
      end
    end
  end
end
