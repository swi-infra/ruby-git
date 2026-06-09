# frozen_string_literal: true

require 'git/commands/gc'
require 'git/commands/repack'

module Git
  class Repository
    # Facade methods for repository maintenance and optimization operations
    #
    # These methods pack objects, compress history, prune unreachable objects, and
    # otherwise keep the repository in good health.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Maintenance
      # Repack loose objects into pack files
      #
      # Packs all unpacked objects and removes redundant pack files. This is
      # equivalent to running `git repack -a -d`, which packs all objects into a
      # single pack and deletes any packs that become redundant.
      #
      # This method uses the fixed options `a: true, d: true` (matching the 4.x
      # behavior). No additional options are exposed.
      #
      # @example Repack the repository
      #   repo.repack
      #
      # @return [String] the stdout from `git repack`, which may include a
      #   progress summary such as:
      #
      #   ```
      #   Counting objects: 450, done.
      #   Compressing objects: 100% (210/210), done.
      #   Writing objects: 100% (450/450), done.
      #   Total 450 (delta 185), reused 390 (delta 150)
      #   ```
      #
      #   Returns an empty string when the repository is already fully packed.
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def repack
        Git::Commands::Repack.new(@execution_context).call(a: true, d: true).stdout
      end

      # Run garbage collection to optimize and clean up the repository
      #
      # Runs `git gc` to perform housekeeping tasks including object compression,
      # pruning of unreachable objects, and ref packing. This is equivalent to
      # running `git gc --prune --aggressive --auto`.
      #
      # This method uses the fixed options `prune: true, aggressive: true, auto: true`
      # (matching the 4.x behavior). No additional options are exposed.
      #
      # @example Run garbage collection
      #   repo.gc
      #
      # @return [String] the stdout from `git gc`, which may include a progress
      #   summary such as:
      #
      #   ```
      #   Counting objects: 945490, done.
      #   Compressing objects: 100% (334718/334718), done.
      #   Writing objects: 100% (945490/945490), done.
      #   Total 945490 (delta 483105), reused 944529 (delta 482309)
      #   Checking connectivity: 948048, done.
      #   ```
      #
      #   Returns an empty string when the repository requires no housekeeping.
      #
      # @raise [Git::FailedError] when git exits with a non-zero exit status
      #
      def gc
        Git::Commands::Gc.new(@execution_context).call(prune: true, aggressive: true, auto: true).stdout
      end
    end
  end
end
