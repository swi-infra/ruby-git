# frozen_string_literal: true

require 'git/commands/clone'
require 'git/commands/init'
require 'git/execution_context/global'
require 'git/repository/path_resolver'
require 'pathname'

module Git
  class Repository
    # Factory class methods for constructing {Git::Repository} instances
    #
    # The four public factories — {clone}, {init}, {open}, {bare} — mirror the
    # top-level `Git.*` entry points but return a {Git::Repository} instead of a
    # {Git::Base}. The top-level entry points continue to return {Git::Base} for
    # backward compatibility.
    #
    # Extended by {Git::Repository}.
    #
    # @api private
    #
    module Factories # rubocop:disable Metrics/ModuleLength
      # Clone a repository into a new directory
      #
      # @example Clone into the default directory
      #   repository = Git::Repository.clone('https://github.com/ruby-git/ruby-git.git')
      #
      # @example Clone into a specific directory
      #   repository = Git::Repository.clone('https://github.com/ruby-git/ruby-git.git', 'local')
      #
      # @example Clone a bare repository
      #   repo_url = 'https://github.com/ruby-git/ruby-git.git'
      #   repository = Git::Repository.clone(repo_url, nil, bare: true)
      #
      # @param repository_url [String] the URL or path of the repository to clone
      #
      # @param directory [String, nil] the local directory name to clone into;
      #   git derives the name from the URL when `nil`
      #
      # @param options [Hash] options that control how the repository is cloned and
      #   how the resulting {Git::Repository} instance is configured
      #
      # @option options [Boolean, nil] :bare clone as a bare repository
      #
      # @option options [Boolean, nil] :mirror set up a mirror of the source (implies bare)
      #
      # @option options [String, nil] :origin the name to use for the remote instead of
      #   the default `'origin'`
      #
      # @option options [String, nil] :branch the branch or tag to check out after cloning
      #
      # @option options [Boolean, nil] :single_branch control single-branch clone behavior
      #
      # @option options [Boolean, String, Array<String>, nil] :recurse_submodules
      #   initialize submodules after cloning; pass `true` to initialize all
      #   submodules or a pathspec string or array for a subset
      #
      # @option options [Integer, nil] :depth create a shallow clone with the given depth
      #
      # @option options [String, nil] :filter request a partial clone
      #
      # @option options [String, nil] :repository a non-standard path for the git
      #   directory of the cloned repository, passed as `--separate-git-dir` to
      #   `git clone`
      #
      # @option options [String, nil, :use_global_config] :git_ssh path to a custom
      #   SSH executable; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.git_ssh`
      #
      # @option options [String, :use_global_config] :binary_path path to the git
      #   binary; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.binary_path`
      #
      # @option options [Logger, nil] :log a logger forwarded to the command layer
      #
      # @option options [String, nil] :index a non-standard path to the index file for
      #   the resulting repository instance
      #
      # @option options [String, Pathname, nil] :chdir run `git clone` from within
      #   this directory
      #
      # @option options [String, Pathname, nil] :path deprecated — use `:chdir` instead
      #
      # @option options [Boolean, nil] :recursive deprecated — use
      #   `:recurse_submodules` instead
      #
      # @option options [String, nil] :remote deprecated — use `:origin` instead
      #
      # @return [Git::Repository] a repository bound to the cloned working copy or
      #   bare repository
      #
      # @raise [Git::FailedError] if `git clone` exits with a non-zero exit status
      #
      # @raise [Git::UnexpectedResultError] if the cloned directory cannot be
      #   determined from git's output
      #
      # @api public
      #
      def clone(repository_url, directory = nil, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        opts, context_opts = prepare_clone_options(options)
        chdir = opts[:chdir]

        context = Git::ExecutionContext::Global.new(
          binary_path: context_opts[:binary_path],
          git_ssh: context_opts[:git_ssh],
          logger: context_opts[:logger]
        )
        clone_result = Git::Commands::Clone.new(context).call(repository_url, directory, **opts)

        clone_dir, cloned_bare = parse_clone_stderr(clone_result.stderr)
        clone_dir = File.join(chdir, clone_dir) if chdir && !Pathname.new(clone_dir).absolute?

        bare = opts[:bare] || opts[:mirror] || cloned_bare
        paths = resolve_clone_paths(clone_dir, bare, context_opts[:index])

        from_paths(
          { git_ssh: context_opts[:git_ssh], binary_path: context_opts[:binary_path], log: context_opts[:logger] },
          paths
        )
      end

      # Create an empty Git repository or reinitialize an existing one
      #
      # @example Initialize in the current directory
      #   repository = Git::Repository.init
      #
      # @example Initialize in a specific directory
      #   repository = Git::Repository.init('/path/to/project')
      #
      # @example Initialize a bare repository
      #   repository = Git::Repository.init('/path/to/project.git', bare: true)
      #
      # @param directory [String] the directory to initialize; defaults to `'.'`
      #
      # @param options [Hash] options that control initialization and the resulting
      #   {Git::Repository} instance
      #
      # @option options [Boolean, nil] :bare create a bare repository at `directory`
      #
      # @option options [String, nil] :initial_branch the name for the initial branch
      #
      # @option options [String, nil] :repository the path at which to create the `.git`
      #   directory (written as a gitfile in the working tree); alias `:separate_git_dir`
      #
      # @option options [String, nil] :separate_git_dir alias for `:repository`
      #
      # @option options [String, nil, :use_global_config] :git_ssh path to a custom
      #   SSH executable; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.git_ssh`
      #
      # @option options [String, :use_global_config] :binary_path path to the git
      #   binary; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.binary_path`
      #
      # @option options [Logger, nil] :log a logger forwarded to the command layer
      #
      # @option options [String, nil] :index a non-standard path to the index file for
      #   the resulting repository instance; ignored when `:bare` is `true`
      #
      # @return [Git::Repository] a repository bound to the newly initialized repository
      #
      # @raise [Git::FailedError] if `git init` exits with a non-zero exit status
      #
      # @api public
      #
      def init(directory = '.', options = {})
        options = options.dup
        if options.key?(:separate_git_dir) && options[:repository].nil?
          options[:repository] = options.delete(:separate_git_dir)
        end

        run_init_command(directory, options)
        open_after_init(directory, options)
      end

      # Open a working copy at an existing path
      #
      # Note: this method opens working copies only. To open a bare repository, use
      # `Git::Repository.bare`.
      #
      # @example Open the working copy in the current directory
      #   repository = Git::Repository.open('.')
      #
      # @param working_dir [String] the path to the root of the working copy
      #
      #   May be any path inside the working tree when `:repository` is not given.
      #
      # @param options [Hash] options that control how the repository is located
      #
      # @option options [String] :repository a non-standard path to the `.git`
      #   directory
      #
      #   When given, `working_dir` is used as-is (the working tree root is not
      #   auto-detected).
      #
      # @option options [String] :index a non-standard path to the index file
      #
      # @option options [Logger] :log a logger forwarded to the command layer
      #
      # @option options [String, nil, :use_global_config] :git_ssh
      #   path to a custom SSH executable; pass `:use_global_config` (the default)
      #   to use `Git::Base.config.git_ssh`
      #
      # @option options [String, :use_global_config] :binary_path
      #   path to the git binary; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.binary_path`
      #
      # @return [Git::Repository] a repository bound to the resolved paths
      #
      # @raise [ArgumentError] if `working_dir` is not a directory or is not inside
      #   a git working tree
      #
      # @api public
      #
      def open(working_dir, options = {})
        raise ArgumentError, "'#{working_dir}' is not a directory" unless Dir.exist?(working_dir)

        working_dir = resolve_open_working_dir(working_dir, options) unless options[:repository]

        paths = PathResolver.resolve_paths(
          working_directory: working_dir,
          repository: options[:repository],
          index: options[:index]
        )

        from_paths(options, paths)
      end

      # Open an existing bare repository at `git_dir`
      #
      # @example Open a bare repository
      #   repository = Git::Repository.bare('/path/to/repo.git')
      #
      # @param git_dir [String] the path to the bare repository directory
      #
      # @param options [Hash] options forwarded to the constructed repository
      #
      # @option options [Logger] :log a logger forwarded to the command layer
      #
      # @option options [String, nil, :use_global_config] :git_ssh
      #   path to a custom SSH executable; pass `:use_global_config` (the default)
      #   to use `Git::Base.config.git_ssh`
      #
      # @option options [String, :use_global_config] :binary_path
      #   path to the git binary; pass `:use_global_config` (the default) to use
      #   `Git::Base.config.binary_path`
      #
      # @return [Git::Repository] a repository bound to the bare repository directory
      #
      # @api public
      #
      def bare(git_dir, options = {})
        paths = PathResolver.resolve_paths(repository: git_dir, bare: true)

        from_paths(options, paths)
      end

      private

      # Resolve the worktree root to use as the working directory for {.open}
      #
      # @param working_dir [String] a path inside the working tree
      # @param options [Hash] the caller-supplied options hash from {.open}
      # @return [String] the absolute path to the root of the working tree
      # @raise [ArgumentError] if `working_dir` is not inside a git working tree
      # @api private
      #
      def resolve_open_working_dir(working_dir, options)
        PathResolver.root_of_worktree(
          working_dir,
          binary_path: options.fetch(:binary_path, :use_global_config),
          git_ssh: options.fetch(:git_ssh, :use_global_config)
        )
      end

      # Build a repository from caller options and resolved paths
      #
      # @param options [Hash] the caller-supplied options (`:git_ssh`, `:binary_path`, `:log`)
      # @param paths [Hash{Symbol => (String, nil)}] the resolved paths
      # @return [Git::Repository] the constructed repository
      # @api private
      #
      def from_paths(options, paths)
        new(execution_context: Git::ExecutionContext::Repository.from_hash(
          options.merge(paths), logger: options[:log]
        ))
      end

      # Extract facade-level options from the raw clone options and return command-ready options
      #
      # Returns `[command_opts, context_opts]` where `command_opts` is the caller's options
      # with facade-level keys removed; remaining keys are forwarded to `Git::Commands::Clone`,
      # which will raise `ArgumentError` for any unsupported ones. `context_opts` contains
      # `{logger:, git_ssh:, binary_path:, index:}` for building the execution context and
      # post-clone path resolution.
      #
      # @param options [Hash] raw caller-supplied options
      # @return [Array(Hash, Hash)] command options and context options
      # @api private
      #
      def prepare_clone_options(options) # rubocop:disable Metrics/MethodLength
        opts = options.dup
        deprecate_clone_path_option!(opts)
        deprecate_clone_recursive_option!(opts)
        deprecate_clone_remote_option!(opts)

        context_opts = {
          logger: opts.delete(:log),
          git_ssh: opts.key?(:git_ssh) ? opts.delete(:git_ssh) : :use_global_config,
          binary_path: opts.key?(:binary_path) ? opts.delete(:binary_path) : :use_global_config,
          index: opts.delete(:index)
        }
        opts[:separate_git_dir] = opts.delete(:repository) if opts.key?(:repository)

        [opts, context_opts]
      end

      # Resolve paths for the cloned repository
      #
      # @param clone_dir [String] the directory reported by `git clone`
      # @param bare [Boolean] whether the clone is bare
      # @param index [String, nil] optional custom index path
      # @return [Hash{Symbol => (String, nil)}] resolved path hash
      # @api private
      #
      def resolve_clone_paths(clone_dir, bare, index)
        args = bare ? { repository: clone_dir, bare: true } : { working_directory: clone_dir }
        PathResolver.resolve_paths(**args, index: index)
      end

      # Run the `git init` command using a global execution context
      #
      # @param directory [String] the directory to initialize
      # @param options [Hash] the normalized options hash (after alias resolution)
      # @return [Git::CommandLineResult]
      # @api private
      #
      def run_init_command(directory, options)
        git_ssh = options.fetch(:git_ssh, :use_global_config)
        binary_path = options.fetch(:binary_path, :use_global_config)

        init_opts = options.slice(:bare, :initial_branch)
        init_opts[:separate_git_dir] = options[:repository] if options.key?(:repository)

        context = Git::ExecutionContext::Global.new(
          binary_path: binary_path, git_ssh: git_ssh, logger: options[:log]
        )
        Git::Commands::Init.new(context).call(directory, **init_opts)
      end

      # Open the repository produced by `git init`
      #
      # @param directory [String] the initialized directory
      # @param options [Hash] the normalized options hash
      # @return [Git::Repository]
      # @api private
      #
      def open_after_init(directory, options) # rubocop:disable Metrics/MethodLength
        open_opts = {
          git_ssh: options.fetch(:git_ssh, :use_global_config),
          binary_path: options.fetch(:binary_path, :use_global_config)
        }
        open_opts[:log] = options[:log] if options[:log]

        if options[:bare]
          bare(options[:repository] || directory, open_opts)
        else
          open_opts[:index] = options[:index] if options[:index]
          open_opts[:repository] = options[:repository] if options[:repository]
          self.open(directory, open_opts)
        end
      end

      # Parse the clone directory and bare status from `git clone` stderr output
      #
      # @param stderr [String] stderr output from `git clone`
      # @return [Array(String, Boolean)] the clone directory path and whether it is bare
      # @raise [Git::UnexpectedResultError] if the stderr cannot be parsed
      # @api private
      #
      def parse_clone_stderr(stderr)
        match = stderr.match(/Cloning into (?:(bare repository) )?'(.+)'\.\.\./)
        raise Git::UnexpectedResultError, "Unable to determine clone directory from: #{stderr}" unless match

        [match[2], !match[1].nil?]
      end

      # Handle the deprecated `:path` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      # @return [void]
      # @api private
      #
      def deprecate_clone_path_option!(opts)
        return unless opts.key?(:path)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn('The :path option for Git::Lib#clone is deprecated, use :chdir instead')
        end
        path = opts.delete(:path)
        opts[:chdir] ||= path
      end

      # Handle the deprecated `:recursive` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      # @return [void]
      # @api private
      #
      def deprecate_clone_recursive_option!(opts)
        return unless opts.key?(:recursive)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn(
            'The :recursive option for Git::Lib#clone is deprecated, use :recurse_submodules instead'
          )
        end
        opts[:recurse_submodules] = opts.delete(:recursive)
      end

      # Handle the deprecated `:remote` option for {clone}
      #
      # @param opts [Hash] clone options (mutated in place)
      # @return [void]
      # @api private
      #
      def deprecate_clone_remote_option!(opts)
        return unless opts.key?(:remote)

        if defined?(Git::Deprecation)
          Git::Deprecation.warn('The :remote option for Git::Lib#clone is deprecated, use :origin instead')
        end
        opts[:origin] = opts.delete(:remote)
      end
    end
  end
end
