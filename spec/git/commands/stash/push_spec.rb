# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/push'

RSpec.describe Git::Commands::Stash::Push do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no options (default stash)' do
      it 'calls git stash push' do
        expect(execution_context).to receive(:command).with('stash', 'push')
        command.call
      end
    end

    context 'with :message option' do
      it 'adds -m flag with message' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--message=WIP changes')
        command.call(message: 'WIP changes')
      end

      it 'accepts :m alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--message=WIP')
        command.call(m: 'WIP')
      end

      it 'handles message with special characters' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--message=Fix "bug" in code')
        command.call(message: 'Fix "bug" in code')
      end
    end

    context 'with :patch option' do
      it 'adds -p flag for interactive selection' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--patch')
        command.call(patch: true)
      end

      it 'accepts :p alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--patch')
        command.call(p: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'push')
        command.call(patch: false)
      end
    end

    context 'with :staged option' do
      it 'adds -S flag to stash only staged changes' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--staged')
        command.call(staged: true)
      end

      it 'accepts :S alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--staged')
        command.call(S: true)
      end
    end

    context 'with :keep_index option' do
      it 'adds --keep-index flag when true' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--keep-index')
        command.call(keep_index: true)
      end

      it 'adds --no-keep-index flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--no-keep-index')
        command.call(keep_index: false)
      end

      it 'accepts :k alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--keep-index')
        command.call(k: true)
      end
    end

    context 'with :include_untracked option' do
      it 'adds -u flag to include untracked files' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--include-untracked')
        command.call(include_untracked: true)
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--include-untracked')
        command.call(u: true)
      end
    end

    context 'with :all option' do
      it 'adds -a flag to include ignored and untracked files' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--all')
        command.call(all: true)
      end

      it 'accepts :a alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--all')
        command.call(a: true)
      end
    end

    context 'with :quiet option' do
      it 'adds -q flag to suppress output' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--quiet')
        command.call(quiet: true)
      end

      it 'accepts :q alias' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--quiet')
        command.call(q: true)
      end
    end

    context 'with :pathspec_from_file option' do
      it 'adds --pathspec-from-file flag' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--pathspec-from-file=paths.txt')
        command.call(pathspec_from_file: 'paths.txt')
      end

      it 'supports reading from stdin with -' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--pathspec-from-file=-')
        command.call(pathspec_from_file: '-')
      end
    end

    context 'with :pathspec_file_nul option' do
      it 'adds --pathspec-file-nul flag' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--pathspec-from-file=paths.txt', '--pathspec-file-nul'
        )
        command.call(pathspec_from_file: 'paths.txt', pathspec_file_nul: true)
      end
    end

    context 'with paths (pathspecs)' do
      it 'adds paths after -- separator' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--', 'file.txt')
        command.call('file.txt')
      end

      it 'accepts multiple paths' do
        expect(execution_context).to receive(:command).with('stash', 'push', '--', 'file1.txt', 'file2.txt')
        command.call('file1.txt', 'file2.txt')
      end

      it 'combines paths with options' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--message=Partial stash', '--', 'src/'
        )
        command.call('src/', message: 'Partial stash')
      end
    end

    context 'with multiple options combined' do
      it 'combines keep_index with message' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--keep-index', '--message=Testing'
        )
        command.call(keep_index: true, message: 'Testing')
      end

      it 'combines include_untracked with quiet and message' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--include-untracked', '--quiet', '--message=WIP'
        )
        command.call(include_untracked: true, quiet: true, message: 'WIP')
      end

      it 'combines staged with paths' do
        expect(execution_context).to receive(:command).with(
          'stash', 'push', '--staged', '--', 'src/', 'lib/'
        )
        command.call('src/', 'lib/', staged: true)
      end
    end
  end
end
