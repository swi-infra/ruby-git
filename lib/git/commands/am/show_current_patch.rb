# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements the `git am --show-current-patch` command
      #
      # Shows the message currently being applied when `git am` has stopped due to
      # conflicts.
      #
      # @example Show the current patch
      #   show_cmd = Git::Commands::Am::ShowCurrentPatch.new(execution_context)
      #   show_cmd.call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see Git::Commands::Am
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class ShowCurrentPatch < Git::Commands::Base
        arguments do
          literal 'am'
          flag_or_value_option :show_current_patch, inline: true, type: [TrueClass, String]
        end

        # @overload call(format = true, **options)
        #
        #   Execute the `git am --show-current-patch` command
        #
        #   @param format [true, String] optional format: `'diff'` emits
        #     `--show-current-patch=diff` (diff portion only); `'raw'` emits
        #     `--show-current-patch=raw` (full raw email)
        #
        #     When omitted, emits `--show-current-patch` and git defaults to `raw`.
        #
        #   @return [Git::CommandLineResult] the result of calling `git am --show-current-patch`
        #
        #   @raise [ArgumentError] if `format` is not `true` or a `String`, or if
        #     unsupported keyword options are passed
        #
        #   @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def call(format = true, **) # rubocop:disable Style/OptionalBooleanParameter
          super(**, show_current_patch: format)
        end
      end
    end
  end
end
