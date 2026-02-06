# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/diff/numstat'

RSpec.describe Git::Commands::Diff::Numstat, :integration do
  include_context 'in a diff test repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    # Tests focusing on command execution and raw output format
    # (Parsing logic is tested in parser specs; end-to-end integration in facade specs)

    describe 'basic command execution' do
      it 'returns CommandLineResult' do
        result = command.call('initial', 'after_modify')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).not_to be_empty
      end

      it 'includes numstat format in output' do
        result = command.call('initial', 'after_modify')

        # Numstat format: <insertions>\t<deletions>\t<path>
        expect(result.stdout).to match(/^\d+\t\d+\t.+$/)
      end

      it 'includes shortstat summary line' do
        result = command.call('initial', 'after_modify')

        # Shortstat format: " <n> files changed, <n> insertions(+), <n> deletions(-)"
        expect(result.stdout).to match(/\d+ file.* changed, \d+ insertion/)
      end
    end

    describe 'rename detection' do
      it 'shows renamed files with arrow syntax in output' do
        result = command.call('after_modify', 'after_rename')

        # Renamed files shown as: old_name => new_name
        expect(result.stdout).to match(/.*=>.*$/)
      end
    end

    describe 'binary file handling' do
      it 'shows dash (-) for binary files' do
        result = command.call('after_add', 'after_binary')

        # Binary files show "-\t-\t<path>"
        expect(result.stdout).to match(/-\t-\timage\.png/)
      end
    end

    describe 'multiple files' do
      # Use after_utf8_rename on Windows since tab filename is skipped
      let(:multi_base_tag) { Gem.win_platform? ? 'after_utf8_rename' : 'after_tab_filename' }

      it 'includes all changed files in output' do
        result = command.call(multi_base_tag, 'after_multi')

        expect(result.stdout).to include('lib/main.rb')
        expect(result.stdout).to include('lib/helper.rb')
        expect(result.stdout).to include('CHANGELOG.md')
      end
    end

    describe 'files with spaces in paths' do
      it 'includes paths with spaces in output' do
        result = command.call('after_mode_change', 'after_spaces')

        # Paths with spaces may or may not be quoted in numstat output
        expect(result.stdout).to include('path with spaces/file name.txt')
      end
    end

    describe 'dirstat option' do
      it 'includes directory statistics when requested' do
        result = command.call('initial', 'after_multi', dirstat: true)

        # Dirstat format: " <percentage>% <directory>/"
        expect(result.stdout).to match(%r{\d+\.\d+% .+/})
      end
    end

    describe 'pathspec filtering' do
      it 'limits output to matching pathspecs' do
        result = command.call('after_spaces', 'after_multi', pathspecs: ['lib/'])

        # Output should only include lib/ files
        lines = result.stdout.lines.grep(/^\d+\t\d+\t/)
        lines.each do |line|
          expect(line).to match(%r{\tlib/})
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
