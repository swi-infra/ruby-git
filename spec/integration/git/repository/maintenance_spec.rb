# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/maintenance'
require 'git/execution_context/repository'

# Integration tests for Git::Repository::Maintenance.
#
# Both methods are exercised against a real repository to confirm they invoke git
# successfully and return the stdout string. The visible content of that string
# depends on internal pack heuristics that vary across git versions, so assertions
# check the type rather than the exact text.

RSpec.describe Git::Repository::Maintenance, :integration do
  include_context 'in an empty repository'

  let(:execution_context) { Git::ExecutionContext::Repository.from_base(repo) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  before do
    write_file('README.md', "hello world\n")
    repo.add(all: true)
    repo.commit('Initial commit')
  end

  describe '#repack' do
    it 'returns a String' do
      expect(described_instance.repack).to be_a(String)
    end
  end

  describe '#gc' do
    it 'returns a String' do
      expect(described_instance.gc).to be_a(String)
    end
  end
end
