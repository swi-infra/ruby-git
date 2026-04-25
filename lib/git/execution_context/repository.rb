# frozen_string_literal: true

require 'git/execution_context'

module Git
  class ExecutionContext
    # Execution context for repository-bound git commands
    #
    # Manages the git environment for commands that operate within an existing
    # repository — setting `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, and
    # `GIT_SSH` — and prepending `--git-dir` / `--work-tree` to every git
    # invocation via {#global_opts}.
    #
    # ### Construction
    #
    # Prefer the factory class methods over `new` when building from a
    # {Git::Base} object or a hash:
    #
    #   context = Git::ExecutionContext::Repository.from_base(base)
    #   context = Git::ExecutionContext::Repository.from_hash(repository: '/repo/.git', ...)
    #
    # @api private
    #
    class Repository < ExecutionContext
      # Creates a Repository context from a {Git::Base} instance
      #
      # @param base_object [Git::Base] the base Git object to derive context from
      #
      # @param logger [Logger, nil] optional logger forwarded to the CommandLine layer
      #
      # @return [Git::ExecutionContext::Repository] the new repository context
      #
      def self.from_base(base_object, logger: nil)
        new(
          git_dir: base_object.repo.to_s,
          git_index_file: base_object.index&.to_s,
          git_work_dir: base_object.dir&.to_s,
          git_ssh: base_object.git_ssh,
          logger: logger
        )
      end

      # Creates a Repository context from the hash format used by {Git::Base.new}
      #
      # Expected keys: `:repository`, `:working_directory`, `:index`, `:git_ssh`
      #
      # @param base_hash [Hash] the hash of repository configuration values
      #
      # @param logger [Logger, nil] optional logger forwarded to the CommandLine layer
      #
      # @return [Git::ExecutionContext::Repository] the new repository context
      #
      def self.from_hash(base_hash, logger: nil)
        new(
          git_dir: base_hash[:repository],
          git_index_file: base_hash[:index],
          git_work_dir: base_hash[:working_directory],
          git_ssh: base_hash.key?(:git_ssh) ? base_hash[:git_ssh] : :use_global_config,
          logger: logger
        )
      end

      # Creates a new repository execution context
      #
      # @param git_dir [String, nil] path to the `.git` directory
      #
      # @param git_work_dir [String, nil] path to the working tree
      #
      # @param git_index_file [String, nil] path to the index file
      #
      # @param git_ssh [String, nil, :use_global_config] SSH wrapper path, `nil` to
      #   unset, or `:use_global_config` (default) to inherit from {Git::Base.config}
      #
      # @param logger [Logger, nil] optional logger forwarded to the CommandLine layer
      #
      def initialize(git_dir:, git_work_dir: nil, git_index_file: nil, git_ssh: :use_global_config, logger: nil)
        super(logger: logger)
        @git_dir = git_dir
        @git_work_dir = git_work_dir
        @git_index_file = git_index_file
        @git_ssh = git_ssh
      end

      private

      # Returns environment variable overrides for this repository
      #
      # Per `Process.spawn` semantics, a value of `nil` unsets the variable.
      #
      # @param additional_overrides [Hash<String, String|nil>] per-call overrides
      #   merged on top of the base hash
      #
      # @return [Hash<String, String|nil>] the merged environment variable overrides
      #
      def env_overrides(**additional_overrides)
        {
          'GIT_DIR' => @git_dir,
          'GIT_WORK_TREE' => @git_work_dir,
          'GIT_INDEX_FILE' => @git_index_file,
          'GIT_SSH' => resolved_git_ssh,
          'GIT_EDITOR' => 'true',
          'LC_ALL' => 'en_US.UTF-8'
        }.merge(additional_overrides)
      end

      # Returns global options prepended to every git invocation for this repository
      #
      # @return [Array<String>] the global options array including `--git-dir` and
      #   `--work-tree` when set
      #
      def global_opts
        [].tap do |opts|
          opts << "--git-dir=#{@git_dir}" unless @git_dir.nil?
          opts << "--work-tree=#{@git_work_dir}" unless @git_work_dir.nil?
          opts.concat(STATIC_GLOBAL_OPTS)
        end
      end

      # Resolves the effective SSH wrapper path
      #
      # @return [String, nil] the SSH wrapper path, or nil to unset the variable
      #
      def resolved_git_ssh
        return Git::Base.config.git_ssh if @git_ssh == :use_global_config

        @git_ssh
      end
    end
  end
end
