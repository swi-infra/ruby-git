# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Apply stashed changes and remove from stash list
      #
      # Like {Apply}, but removes the stash from the stash list after
      # applying, unless there are conflicts.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Pop the latest stash
      #   Git::Commands::Stash::Pop.new(context).call
      #
      # @example Pop a specific stash
      #   Git::Commands::Stash::Pop.new(context).call('stash@{2}')
      #
      # @example Pop and restore index state
      #   Git::Commands::Stash::Pop.new(context).call(index: true)
      #
      class Pop
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          flag :index
          flag %i[quiet q], args: '--quiet'
          positional :stash
        end.freeze

        # Creates a new Pop command instance
        #
        # @param context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(context)
          @context = context
        end

        # Pop stashed changes
        #
        # @overload call(**options)
        #
        #   Pop the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :index (nil) restore the index state as well
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        # @overload call(stash, **options)
        #
        #   Pop a specific stash
        #
        #   @param stash [String, nil] stash reference (e.g., 'stash@\\{0}', '0');
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :index (nil) restore the index state as well
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        # @return [String] the command output
        #
        def call(*, **)
          args = ARGS.build(*, **)
          @context.command('stash', 'pop', *args)
        end
      end
    end
  end
end
