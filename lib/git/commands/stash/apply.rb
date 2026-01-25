# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Stash
      # Apply stashed changes to the working directory
      #
      # Applies the changes recorded in a stash to the working tree.
      # Unlike {Pop}, this does not remove the stash from the stash list.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      # @api private
      #
      # @example Apply the latest stash
      #   Git::Commands::Stash::Apply.new(context).call
      #
      # @example Apply a specific stash
      #   Git::Commands::Stash::Apply.new(context).call('stash@{2}')
      #
      # @example Apply and restore index state
      #   Git::Commands::Stash::Apply.new(context).call(index: true)
      #
      class Apply
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          flag :index
          flag %i[quiet q], args: '--quiet'
          positional :stash
        end.freeze

        # Creates a new Apply command instance
        #
        # @param context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(context)
          @context = context
        end

        # Apply stashed changes
        #
        # @overload call(**options)
        #
        #   Apply the latest stash
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :index (nil) restore the index state as well
        #
        #   @option options [Boolean] :quiet (nil) suppress output messages. Alias: :q
        #
        # @overload call(stash, **options)
        #
        #   Apply a specific stash
        #
        #   @param stash [String] stash reference (e.g., 'stash@\\{0}', '0')
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
          @context.command('stash', 'apply', *args)
        end
      end
    end
  end
end
