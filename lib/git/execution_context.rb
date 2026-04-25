# frozen_string_literal: true

module Git
  # Base class for execution contexts that run git commands
  #
  # Provides the shared `command_capturing` and `command_streaming` entry points
  # used by {Git::Commands::Base} subclasses. Subclasses must implement the
  # private `env_overrides` and `global_opts` methods to supply the environment
  # variables and global options appropriate for their scope.
  #
  # Concrete subclasses:
  # - {Git::ExecutionContext::Repository} — for repository-bound commands (`add`, `commit`, …)
  # - {Git::ExecutionContext::Global} — for commands that do not require an existing repository
  #   (`init`, `clone`, `version`)
  #
  # @api private
  #
  class ExecutionContext
    # Default keyword arguments accepted by {#command_capturing}.
    #
    # `timeout: nil` is intentional — the global timeout from {Git.config} is
    # applied at call-time so that changes to the config are respected.
    #
    COMMAND_CAPTURING_ARG_DEFAULTS = {
      in: nil,
      out: nil,
      err: nil,
      normalize: true,
      chomp: true,
      merge: false,
      chdir: nil,
      timeout: nil,
      env: {},
      raise_on_failure: true
    }.freeze

    # Default keyword arguments accepted by {#command_streaming}.
    COMMAND_STREAMING_ARG_DEFAULTS = {
      in: nil,
      out: nil,
      err: nil,
      chdir: nil,
      timeout: nil,
      env: {},
      raise_on_failure: true
    }.freeze

    # Static git global options applied to every invocation.
    #
    # These ensure deterministic, script-friendly output regardless of the
    # user's local git configuration.
    #
    STATIC_GLOBAL_OPTS = %w[
      -c core.quotePath=true
      -c core.editor=false
      -c color.ui=false
      -c color.advice=false
      -c color.diff=false
      -c color.grep=false
      -c color.push=false
      -c color.remote=false
      -c color.showBranch=false
      -c color.status=false
      -c color.transport=false
    ].freeze

    # Creates a new execution context
    #
    # @param logger [Logger, nil] optional logger forwarded to the CommandLine layer
    #
    def initialize(logger: nil)
      @logger = logger
    end

    # Runs a git command and returns the result
    #
    # By default, raises {Git::FailedError} if the command exits with a non-zero
    # status. Pass `raise_on_failure: false` to suppress this behavior.
    #
    # @overload command_capturing(*args, **options_hash)
    #
    #   Runs a git command and returns the result
    #
    #   Args should exclude the 'git' command itself and global options. Remember to
    #   splat the arguments if given as an array.
    #
    #   @example Run git log
    #     result = command_capturing('log', '--pretty=oneline')
    #     result.stdout #=> "abc123 First commit\ndef456 Second commit\n"
    #
    #   @example Using an array of arguments
    #     args = ['log', '--pretty=oneline']
    #     result = command_capturing(*args)
    #
    #   @example Suppress raising on failure
    #     result = command_capturing('show', 'nonexistent', raise_on_failure: false)
    #     result.status.success? #=> false
    #
    #   @param args [Array<String>] the command and its arguments
    #
    #   @param options_hash [Hash] the options to pass to the command
    #
    #   @option options_hash [IO, nil] :in the IO object to use as stdin, or nil to
    #     inherit the parent process stdin
    #
    #     Must be a real IO object with a file descriptor.
    #
    #   @option options_hash [IO, String, #write, nil] :out the destination for
    #     captured stdout
    #
    #   @option options_hash [IO, String, #write, nil] :err the destination for
    #     captured stderr
    #
    #   @option options_hash [Boolean] :normalize true to normalize the output
    #     encoding to UTF-8
    #
    #   @option options_hash [Boolean] :chomp true to remove trailing newlines from
    #     the output
    #
    #   @option options_hash [Boolean] :merge true to merge stdout and stderr into a
    #     single output
    #
    #   @option options_hash [String, nil] :chdir the directory to run the command in
    #
    #   @option options_hash [Hash] :env additional environment variable overrides
    #     for this command
    #
    #   @option options_hash [Boolean] :raise_on_failure (true) whether to raise on
    #     non-zero exit
    #
    #   @option options_hash [Numeric, nil] :timeout the maximum seconds to wait for
    #     the command to complete
    #
    #     If timeout is nil, the global timeout from {Git::Config} is used.
    #
    #     If timeout is zero, the timeout will not be enforced.
    #
    #     If the command times out, it is killed via a `SIGKILL` signal and
    #     `Git::TimeoutError` is raised.
    #
    #     If the command does not respond to SIGKILL, it will hang this method.
    #
    #   @return [Git::CommandLineResult] the result of the command
    #
    #   @raise [ArgumentError] if an unknown option is passed
    #
    #   @raise [Git::FailedError] if the command failed (when raise_on_failure is
    #     true)
    #
    #   @raise [Git::SignaledError] if the command was signaled
    #
    #   @raise [Git::TimeoutError] if the command times out
    #
    #   @raise [Git::ProcessIOError] if an exception was raised while collecting
    #     subprocess output
    #
    #     The exception's `result` attribute is a {Git::CommandLineResult} which will
    #     contain the result of the command including the exit status, stdout, and stderr.
    #
    # @note Individual command classes (under {Git::Commands}) can selectively expose
    #   `:timeout` and `:env` and other options to their callers by declaring them as
    #   execution options in their Arguments DSL definition and forwarding them to
    #   this method. See {Git::Commands::Clone#call} for an example of a command that
    #   exposes `:timeout`.
    #
    # @see Git::CommandLine::Capturing#run
    #
    # @see #command_line_capturing
    #
    def command_capturing(*, **options_hash)
      options_hash = COMMAND_CAPTURING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_CAPTURING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_capturing.run(*, raise_on_failure: raise_on_failure, env: env, **options_hash)
    end

    # Runs a git command using the streaming (non-capturing) execution path
    #
    # Unlike {#command_capturing}, stdout is NOT buffered in memory. It is
    # written only to the IO object provided via the `out:` option. Stderr is
    # captured internally via a StringIO for error diagnostics.
    #
    # Use this entry point when you want to stream large output (e.g. blob
    # content from cat-file) without creating memory pressure.
    #
    # @overload command_streaming(*args, **options_hash)
    #
    #   Streams a git command's output to the provided IO object
    #
    #   @example Stream blob content to a file
    #     File.open('blob.bin', 'wb') do |f|
    #       command_streaming('cat-file', 'blob', 'HEAD:large_file.bin', out: f)
    #     end
    #
    #   @param args [Array<String>] the git command and its arguments
    #
    #   @param options_hash [Hash] the options to pass to the command
    #
    #   @option options_hash [IO, nil] :in the IO object to use as stdin, or nil to
    #     inherit the parent process stdin
    #
    #     Must be a real IO object with a file descriptor.
    #
    #   @option options_hash [#write, nil] :out destination for streamed stdout
    #
    #   @option options_hash [#write, nil] :err an optional additional destination
    #     to receive stderr output in real time
    #
    #     Stderr is always captured internally; when `err:` is supplied, writes are
    #     teed to both the internal buffer and this destination. `result.stderr`
    #     always reflects the internal capture.
    #
    #   @option options_hash [String, nil] :chdir the directory to run the command in
    #
    #   @option options_hash [Hash] :env additional environment variable overrides
    #     for this command
    #
    #   @option options_hash [Boolean] :raise_on_failure (true) whether to raise on
    #     non-zero exit
    #
    #   @option options_hash [Numeric, nil] :timeout
    #     the maximum seconds to wait for the command to complete
    #
    #     If timeout is nil, the global timeout from {Git::Config} is used.
    #
    #     If timeout is zero, the timeout will not be enforced.
    #
    #     If the command times out, it is killed via a `SIGKILL` signal and
    #     `Git::TimeoutError` is raised.
    #
    #     If the command does not respond to SIGKILL, it will hang this method.
    #
    #   @return [Git::CommandLineResult] the result of the command
    #
    #     `result.stdout` will always be `''` — stdout was streamed to `out:`.
    #
    #     `result.stderr` contains any stderr output captured for diagnostics.
    #
    #   @raise [ArgumentError] if an unknown option is passed
    #
    #   @raise [Git::FailedError] if the command failed (when raise_on_failure is true)
    #
    #   @raise [Git::SignaledError] if the command was signaled
    #
    #   @raise [Git::TimeoutError] if the command times out
    #
    #   @raise [Git::ProcessIOError] if an exception was raised while collecting
    #     subprocess output
    #
    # @see Git::CommandLine::Streaming#run
    #
    # @see #command_line_streaming
    #
    def command_streaming(*, **options_hash)
      options_hash = COMMAND_STREAMING_ARG_DEFAULTS.merge(options_hash)
      options_hash[:timeout] ||= Git.config.timeout

      extra_options = options_hash.keys - COMMAND_STREAMING_ARG_DEFAULTS.keys
      raise ArgumentError, "Unknown options: #{extra_options.join(', ')}" if extra_options.any?

      env = options_hash.delete(:env)
      raise_on_failure = options_hash.delete(:raise_on_failure)
      command_line_streaming.run(*, raise_on_failure: raise_on_failure, env: env, **options_hash)
    end

    # Returns the installed git version
    #
    # The result is memoized per instance.
    #
    # @return [Git::Version] the installed git version
    #
    # @raise [Git::Error] if the version string cannot be parsed
    #
    def git_version
      @git_version ||= begin
        output = Git::Commands::Version.new(self).call.stdout
        Git::Version.parse(output)
      rescue ArgumentError => e
        raise Git::Error, "Unable to parse git version from: #{output.inspect} (#{e.message})"
      end
    end

    private

    # Returns a Hash of environment variable overrides for this context
    #
    # @abstract Subclasses must implement this method.
    #
    # @return [Hash<String, String|nil>] the merged environment variable overrides
    #
    def env_overrides(**_additional_overrides)
      raise NotImplementedError, "#{self.class} must implement #env_overrides"
    end

    # Returns the Array of git global option strings for this context
    #
    # @abstract Subclasses must implement this method.
    #
    # @return [Array<String>] the global options to prepend to every git invocation
    #
    def global_opts
      raise NotImplementedError, "#{self.class} must implement #global_opts"
    end

    # Memoized {Git::CommandLine::Capturing} instance.
    #
    # Created once using the current {#env_overrides} and {#global_opts} so
    # per-command env overrides can be passed to {Git::CommandLine::Capturing#run}
    # via the `env:` keyword.
    #
    # @return [Git::CommandLine::Capturing] the capturing command line instance
    #
    def command_line_capturing
      @command_line_capturing ||=
        Git::CommandLine::Capturing.new(env_overrides, Git::Base.config.binary_path, global_opts, @logger)
    end

    # Memoized {Git::CommandLine::Streaming} instance.
    #
    # @return [Git::CommandLine::Streaming] the streaming command line instance
    #
    def command_line_streaming
      @command_line_streaming ||=
        Git::CommandLine::Streaming.new(env_overrides, Git::Base.config.binary_path, global_opts, @logger)
    end
  end
end
