# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/raw'

RSpec.describe Git::Commands::Diff::Raw, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Tests focusing on command execution and raw output format
    # (Parsing logic is tested in parser specs; end-to-end integration in facade specs)

    describe 'basic command execution' do
      it 'returns CommandLineResult with raw output' do
        result = command.call('initial', 'after_modify')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'includes raw format lines' do
        result = command.call('initial', 'after_modify')

        # Raw format: :src_mode dst_mode src_sha dst_sha status\tpath
        expect(result.stdout).to match(/^:100644 100644 .* M\t/m)
      end

      it 'includes numstat and shortstat in output' do
        result = command.call('initial', 'after_modify')

        # Numstat format
        expect(result.stdout).to match(/^\d+\t\d+\t.+$/m)
        # Shortstat format
        expect(result.stdout).to match(/\d+ file.* changed/)
      end
    end

    describe 'status indicators in output' do
      it 'shows M for modified files' do
        result = command.call('initial', 'after_modify')

        expect(result.stdout).to match(/^:100644 100644 .* M\tREADME\.md$/m)
      end

      it 'shows R with similarity for renamed files' do
        result = command.call('after_modify', 'after_rename')

        # R<similarity>\t<old_path>\t<new_path> or with arrow syntax
        expect(result.stdout).to match(/R\d+/m)
      end

      it 'shows D for deleted files' do
        result = command.call('after_rename', 'after_delete')

        expect(result.stdout).to match(/D\tdocs\.md$/m)
      end

      it 'shows A for added files' do
        result = command.call('after_delete', 'after_add')

        expect(result.stdout).to match(%r{A\tlib/main\.rb$}m)
      end
    end
    describe 'exit code handling' do
      it 'returns exit code 0 with no differences' do
        result = command.call('initial', 'initial')

        expect(result.status.exitstatus).to eq(0)
        expect(result.stdout).to be_empty
      end

      it 'succeeds with differences found' do
        result = command.call('initial', 'after_modify')

        expect(result.status.exitstatus).to be <= 1
        expect(result.stdout).not_to be_empty
      end

      it 'raises FailedError for invalid revision' do
        expect { command.call('nonexistent-ref') }.to raise_error(Git::FailedError)
      end
    end
  end
end
