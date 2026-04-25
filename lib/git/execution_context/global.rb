# frozen_string_literal: true

require 'git/execution_context'

module Git
  class ExecutionContext
    # Execution context for global git commands (no repository required)
    #
    # Used for commands that do not require an existing repository — such as
    # `git init`, `git clone`, and `git version`. Unlike
    # {Git::ExecutionContext::Repository}, this class does not set `GIT_DIR`,
    # `GIT_WORK_TREE`, `GIT_INDEX_FILE`, or `GIT_SSH`, and does not prepend
    # `--git-dir` / `--work-tree` to invocations.
    #
    # @api private
    #
    class Global < ExecutionContext
      # Creates a new global execution context
      #
      # @param logger [Logger, nil] optional logger forwarded to the CommandLine layer
      #
      def initialize(logger: nil)
        super
      end

      private

      # Returns environment variable overrides for global (non-repository) commands
      #
      # Only sets `GIT_EDITOR` and `LC_ALL`; all repository-path variables are
      # intentionally absent.
      #
      # @param additional_overrides [Hash<String, String|nil>] per-call overrides
      #   merged on top of the base hash
      #
      # @return [Hash<String, String|nil>] the merged environment variable overrides
      #
      def env_overrides(**additional_overrides)
        {
          'GIT_EDITOR' => 'true',
          'LC_ALL' => 'en_US.UTF-8'
        }.merge(additional_overrides)
      end

      # Returns global options prepended to every git invocation
      #
      # Contains only the {STATIC_GLOBAL_OPTS} — no `--git-dir` or `--work-tree`.
      #
      # @return [Array<String>] the global options array
      #
      def global_opts
        STATIC_GLOBAL_OPTS.dup
      end
    end
  end
end
