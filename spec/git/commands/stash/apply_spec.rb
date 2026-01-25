# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/apply'

RSpec.describe Git::Commands::Stash::Apply do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (apply latest stash)' do
      it 'calls git stash apply' do
        expect(execution_context).to receive(:command).with('stash', 'apply')
        command.call
      end
    end

    context 'with stash reference' do
      it 'applies specific stash by name' do
        expect(execution_context).to receive(:command).with('stash', 'apply', 'stash@{0}')
        command.call('stash@{0}')
      end

      it 'applies specific stash by index' do
        expect(execution_context).to receive(:command).with('stash', 'apply', 'stash@{2}')
        command.call('stash@{2}')
      end

      it 'applies stash using short form' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '1')
        command.call('1')
      end
    end

    context 'with :index option' do
      it 'adds --index flag to restore index state' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--index')
        command.call(index: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'apply')
        command.call(index: false)
      end
    end

    context 'with :quiet option' do
      it 'adds -q flag to suppress output' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--quiet')
        command.call(quiet: true)
      end

      it 'accepts :q alias' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--quiet')
        command.call(q: true)
      end
    end

    context 'with stash reference and options' do
      it 'combines stash reference with index option' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--index', 'stash@{1}')
        command.call('stash@{1}', index: true)
      end

      it 'combines stash reference with quiet option' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--quiet', 'stash@{0}')
        command.call('stash@{0}', quiet: true)
      end

      it 'combines all options' do
        expect(execution_context).to receive(:command).with('stash', 'apply', '--index', '--quiet', 'stash@{2}')
        command.call('stash@{2}', index: true, quiet: true)
      end
    end
  end
end
