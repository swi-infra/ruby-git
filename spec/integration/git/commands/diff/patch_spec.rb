# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/patch'

RSpec.describe Git::Commands::Diff::Patch, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Tests focusing on command execution and patch output format
    # (Parsing logic is tested in parser specs; end-to-end integration in facade specs)

    describe 'basic command execution' do
      it 'returns CommandLineResult with patch output' do
        result = command.call('initial', 'after_modify')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
        expect(result.stdout).to include('diff --git')
        expect(result.stdout).to include('@@')
      end

      it 'includes numstat and shortstat in output' do
        result = command.call('initial', 'after_modify')

        # Numstat format: <insertions>\t<deletions>\t<path>
        expect(result.stdout).to match(/^\d+\t\d+\t.+$/m)
        # Shortstat format
        expect(result.stdout).to match(/\d+ file.* changed/)
      end

      it 'includes unified diff with context' do
        result = command.call('initial', 'after_modify')

        expect(result.stdout).to include('---')
        expect(result.stdout).to include('+++')
        expect(result.stdout).to include('+## Installation')
      end
    end

    describe 'file change types' do
      describe 'modified files' do
        it 'shows modified file in patch output' do
          result = command.call('initial', 'after_modify')

          expect(result.stdout).to include('diff --git a/README.md b/README.md')
          expect(result.stdout).to include('index ')
          expect(result.stdout).to include('--- a/README.md')
          expect(result.stdout).to include('+++ b/README.md')
        end
      end

      describe 'renamed files' do
        it 'shows renamed file with similarity index' do
          result = command.call('after_modify', 'after_rename')

          expect(result.stdout).to include('rename from README.md')
          expect(result.stdout).to include('rename to docs.md')
          expect(result.stdout).to match(/similarity index \d+%/)
        end
      end

      describe 'deleted files' do
        it 'shows deleted file mode in output' do
          result = command.call('after_rename', 'after_delete')

          expect(result.stdout).to include('deleted file mode')
          expect(result.stdout).to include('--- a/docs.md')
          expect(result.stdout).to include('+++ /dev/null')
        end
      end

      describe 'added files' do
        it 'shows new file mode in output' do
          result = command.call('after_delete', 'after_add')

          expect(result.stdout).to include('new file mode')
          expect(result.stdout).to include('--- /dev/null')
          expect(result.stdout).to include('+++ b/lib/main.rb')
        end
      end

      describe 'binary files' do
        it 'marks binary files in diff output' do
          result = command.call('after_add', 'after_binary')

          expect(result.stdout).to include('Binary files')
          expect(result.stdout).to include('image.png')
        end
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
