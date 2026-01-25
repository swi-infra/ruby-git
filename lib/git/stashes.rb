# frozen_string_literal: true

module Git
  # object that holds all the available stashes
  class Stashes
    include Enumerable

    def initialize(base)
      @stashes = []

      @base = base

      @base.lib.stashes_all.each do |stash_info|
        @stashes.unshift(Git::Stash.new(@base, stash_info.message, save: true))
      end
    end

    #
    # Returns an Array of StashInfo objects for all stash entries.
    #
    # @example Returns Array of stash info objects
    #     stashes = git.stashes.all
    #     stashes.first.index   # => 0
    #     stashes.first.message # => "WIP on main: abc123 Initial commit"
    #
    # @return [Array<Git::StashInfo>] array of stash info objects
    #
    def all
      @base.lib.stashes_all
    end

    def save(message)
      s = Git::Stash.new(@base, message)
      @stashes.unshift(s) if s.saved?
    end

    def apply(index = nil)
      @base.lib.stash_apply(index)
    end

    def clear
      @base.lib.stash_clear
      @stashes = []
    end

    def size
      @stashes.size
    end

    def each(&)
      @stashes.each(&)
    end

    def [](index)
      @stashes[index.to_i]
    end
  end
end
