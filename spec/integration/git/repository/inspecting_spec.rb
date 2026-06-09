# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/inspecting'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Inspecting.
#
# All facade methods are exercised end-to-end here because each performs
# facade-owned processing that benefits from a real git invocation:
#   * #show joins objectish and path into an `objectish:path` expression before
#     calling git, so a real blob read proves the pre-processing produces a
#     valid object specifier.
#   * #fsck parses real `git fsck` stdout into a Git::FsckResult, so a real
#     invocation proves the parsing handles actual output.
#   * #describe performs facade-owned :"exact-match" key translation; a real
#     invocation proves the translation produces a valid command invocation.

RSpec.describe Git::Repository::Inspecting, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#show' do
    before do
      write_file('README.md', "hello world\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    context 'with an objectish and a path' do
      it 'shows the contents of the file at that revision' do
        expect(described_instance.show('HEAD', 'README.md')).to eq("hello world\n")
      end
    end
  end

  describe '#fsck' do
    before do
      write_file('README.md', "hello world\n")
      repo.add(all: true)
      repo.commit('Initial commit')
    end

    it 'returns a Git::FsckResult' do
      expect(described_instance.fsck).to be_a(Git::FsckResult)
    end

    context 'when the repository is healthy' do
      it 'reports no issues' do
        expect(described_instance.fsck).to be_empty
      end
    end

    context 'when a dangling object exists' do
      before do
        write_file('orphan.txt', "orphan content\n")
        Dir.chdir(repo_dir) { execution_context.command_capturing('hash-object', '-w', 'orphan.txt') }
      end

      it 'reports the dangling object' do
        expect(described_instance.fsck.dangling).not_to be_empty
      end
    end
  end

  describe '#describe' do
    before do
      write_file('README.md', "hello world\n")
      repo.add(all: true)
      repo.commit('Initial commit')
      repo.add_tag('v1.0.0', repo.revparse('HEAD'), a: true, m: 'Release v1.0.0')
    end

    it 'returns a String' do
      expect(described_instance.describe).to be_a(String)
    end

    it 'returns the tag name when HEAD is directly tagged' do
      expect(described_instance.describe).to start_with('v1.0.0')
    end

    context 'with an additional commit after the tag' do
      before do
        write_file('file2.txt', "more content\n")
        repo.add(all: true)
        repo.commit('Second commit')
      end

      it 'includes the tag name and commit offset in the description' do
        result = described_instance.describe
        expect(result).to match(/\Av1\.0\.0-\d+-g[0-9a-f]+/)
      end
    end

    context 'with the legacy :"exact-match" key' do
      it 'accepts :"exact-match" without raising an error' do
        expect { described_instance.describe(nil, 'exact-match': true) }.not_to raise_error
      end
    end
  end
end
