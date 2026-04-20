# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Maintenance
      # Run one or more maintenance tasks
      #
      # @example Run all enabled maintenance tasks
      #   Git::Commands::Maintenance::Run.new(execution_context).call
      #
      # @example Run specific tasks in order
      #   Git::Commands::Maintenance::Run.new(execution_context).call(task: ['gc', 'commit-graph'])
      #
      # @example Run tasks only if thresholds are met
      #   Git::Commands::Maintenance::Run.new(execution_context).call(auto: true)
      #
      # @example Run scheduled tasks at a specific frequency
      #   Git::Commands::Maintenance::Run.new(execution_context).call(schedule: 'hourly')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-maintenance/2.54.0
      #
      # @see Git::Commands::Maintenance Git::Commands::Maintenance for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
      #
      # @api private
      #
      class Run < Git::Commands::Base
        requires_git_version '2.30.0'

        arguments do
          literal 'maintenance'
          literal 'run'

          # Options
          flag_option :auto
          flag_or_value_option :schedule, inline: true
          flag_option :quiet
          value_option :task, inline: true, repeatable: true
          execution_option :env
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Run one or more maintenance tasks
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :auto (false) run tasks only if thresholds are met
        #
        #     @option options [true, String, nil] :schedule (nil) run tasks only if time conditions are met
        #
        #       When +true+, runs tasks that are due according to +maintenance.<task>.schedule+
        #       config values.
        #
        #       When a String (+'hourly'+, +'daily'+, or +'weekly'+), runs only tasks scheduled
        #       for that frequency.
        #
        #     @option options [Boolean] :quiet (false) suppress progress and informational messages
        #
        #     @option options [Array<String>, String] :task (nil) specify which task(s) to run
        #
        #       If specified, only the given tasks are run in the specified order.
        #       Otherwise, tasks are determined by config options.
        #       Valid task names: 'commit-graph', 'prefetch', 'gc', 'loose-objects',
        #       'incremental-repack', 'pack-refs', 'reflog-expire', 'rerere-gc', 'worktree-prune'.
        #
        #     @option options [Hash] :env (nil) environment variables to set for the git
        #       process; merged with the default environment; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git maintenance run`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #     @raise [Git::VersionError] if git version is below 2.30.0
      end
    end
  end
end
