# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/drop'

RSpec.describe Git::Commands::Stash::Drop do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments (drop latest stash)' do
      it 'calls git stash drop' do
        expect(execution_context).to receive(:command).with('stash', 'drop')
        command.call
      end
    end

    context 'with stash reference' do
      it 'drops specific stash by name' do
        expect(execution_context).to receive(:command).with('stash', 'drop', 'stash@{0}')
        command.call('stash@{0}')
      end

      it 'drops specific stash by index' do
        expect(execution_context).to receive(:command).with('stash', 'drop', 'stash@{2}')
        command.call('stash@{2}')
      end

      it 'drops stash using short form' do
        expect(execution_context).to receive(:command).with('stash', 'drop', '1')
        command.call('1')
      end
    end

    context 'with :quiet option' do
      it 'adds -q flag to suppress output' do
        expect(execution_context).to receive(:command).with('stash', 'drop', '--quiet')
        command.call(quiet: true)
      end

      it 'accepts :q alias' do
        expect(execution_context).to receive(:command).with('stash', 'drop', '--quiet')
        command.call(q: true)
      end

      it 'does not add flag when false' do
        expect(execution_context).to receive(:command).with('stash', 'drop')
        command.call(quiet: false)
      end
    end

    context 'with stash reference and options' do
      it 'combines stash reference with quiet option' do
        expect(execution_context).to receive(:command).with('stash', 'drop', '--quiet', 'stash@{0}')
        command.call('stash@{0}', quiet: true)
      end
    end
  end
end
