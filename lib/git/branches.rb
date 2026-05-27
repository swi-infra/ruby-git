# frozen_string_literal: true

module Git
  # Collection of all Git branches in a repository
  #
  # Wraps both local and remote-tracking branches and provides filtering,
  # enumeration, and name-based lookup.
  #
  # @example Enumerate all branches
  #   branches = repo.branches
  #   branches.each { |b| puts b.name }
  #
  # @api public
  #
  class Branches
    include Enumerable

    # Creates a new Branches collection populated from the given repository
    #
    # @param base [Git::Base, Git::Repository] the repository to enumerate
    #   branches from
    #
    # @return [void]
    #
    def initialize(base)
      @branches = {}

      @base = base

      repo = base.is_a?(Git::Base) ? base.facade_repository : base
      repo.branches_all.each do |branch_info|
        @branches[branch_info.refname] = Git::Branch.new(base, branch_info)
      end
    end

    # Returns all local (non-remote-tracking) branches
    #
    # @example List local branch names
    #   repo.branches.local.map(&:name)
    #
    # @return [Array<Git::Branch>] the local branches
    #
    def local
      reject(&:remote)
    end

    # Returns all remote-tracking branches
    #
    # @example List remote branch names
    #   repo.branches.remote.map(&:name)
    #
    # @return [Array<Git::Branch>] the remote-tracking branches
    #
    def remote
      self.select(&:remote)
    end

    # Returns the number of branches in the collection
    #
    # @example Count all branches
    #   repo.branches.size  # => 3
    #
    # @return [Integer] the total number of branches
    #
    def size
      @branches.size
    end

    # Iterates over every branch in the collection
    #
    # @overload each
    #
    #   @example Get an enumerator over all branches
    #     enum = repo.branches.each
    #
    #   @return [Enumerator<Git::Branch>] an enumerator over all branches
    #
    # @overload each(&block)
    #
    #   @example Print every branch name
    #     repo.branches.each { |b| puts b.name }
    #
    #   @yield [branch] passes each branch to the block
    #
    #   @yieldparam branch [Git::Branch] a branch in the repository
    #
    #   @yieldreturn [void]
    #
    #   @return [Array<Git::Branch>] the full list of branches
    #
    def each(&)
      @branches.values.each(&)
    end

    # Returns the branch with the given name
    #
    # Supports short names (`'main'`), remote-qualified names
    # (`'working/master'`), and full refspec names
    # (`'remotes/working/master'`).
    #
    # @example Look up a branch by short name
    #   repo.branches['main']
    #
    # @example Look up a remote-tracking branch
    #   repo.branches['working/master']
    #
    # @param branch_name [#to_s] the name of the branch to retrieve
    #
    # @return [Git::Branch, nil] the matching branch, or `nil` if not found
    #
    def [](branch_name)
      @branches.values.each_with_object(@branches) do |branch, branches|
        branches[branch.full] ||= branch

        # This is how Git (version 1.7.9.5) works.
        # Lets you ignore the 'remotes' if its at the beginning of the branch full
        # name (even if is not a real remote branch).
        branches[branch.full.sub('remotes/', '')] ||= branch if branch.full =~ %r{^remotes/.+}
      end[branch_name.to_s]
    end

    # Returns a string listing all branches, prefixed with `*` for the current branch
    #
    # @example Display all branches
    #   puts repo.branches.to_s
    #
    # @return [String] a formatted branch listing
    #
    def to_s
      out = +''
      @branches.each_value do |b|
        out << (b.current ? '* ' : '  ') << b.to_s << "\n"
      end
      out
    end
  end
end
