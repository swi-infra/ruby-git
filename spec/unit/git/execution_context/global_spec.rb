# frozen_string_literal: true

require 'spec_helper'
require 'git/execution_context/global'

RSpec.describe Git::ExecutionContext::Global do
  describe 'inheritance' do
    it 'is a Git::ExecutionContext' do
      expect(described_class.new).to be_a(Git::ExecutionContext)
    end
  end

  describe '#initialize' do
    it 'can be created with no arguments' do
      expect { described_class.new }.not_to raise_error
    end

    it 'accepts an optional logger' do
      logger = double('logger')
      expect { described_class.new(logger: logger) }.not_to raise_error
    end
  end

  describe 'env_overrides (via #send)' do
    let(:context) { described_class.new }

    it 'does not set GIT_DIR' do
      expect(context.send(:env_overrides)).not_to have_key('GIT_DIR')
    end

    it 'does not set GIT_WORK_TREE' do
      expect(context.send(:env_overrides)).not_to have_key('GIT_WORK_TREE')
    end

    it 'does not set GIT_INDEX_FILE' do
      expect(context.send(:env_overrides)).not_to have_key('GIT_INDEX_FILE')
    end

    it 'does not set GIT_SSH' do
      expect(context.send(:env_overrides)).not_to have_key('GIT_SSH')
    end

    it 'sets GIT_EDITOR to "true" (no-op editor)' do
      expect(context.send(:env_overrides)['GIT_EDITOR']).to eq('true')
    end

    it 'sets LC_ALL to "en_US.UTF-8"' do
      expect(context.send(:env_overrides)['LC_ALL']).to eq('en_US.UTF-8')
    end

    it 'merges caller-supplied additional overrides' do
      env = context.send(:env_overrides, 'MY_VAR' => 'val')
      expect(env['MY_VAR']).to eq('val')
    end
  end

  describe 'global_opts (via #send)' do
    let(:context) { described_class.new }

    it 'does not include --git-dir' do
      expect(context.send(:global_opts).grep(/\A--git-dir/)).to be_empty
    end

    it 'does not include --work-tree' do
      expect(context.send(:global_opts).grep(/\A--work-tree/)).to be_empty
    end

    it 'includes the static global opts' do
      expect(context.send(:global_opts)).to include('-c', 'core.quotePath=true')
    end
  end

  describe '#command_capturing' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('git version 2.40.0') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_capturing.run' do
      expect(command_line_double).to receive(:run)
        .with('version', hash_including(raise_on_failure: true, normalize: true))
        .and_return(result)
      context.command_capturing('version')
    end
  end

  describe '#command_streaming' do
    let(:context) { described_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }
    let(:out_io) { StringIO.new }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('clone', hash_including(out: out_io, raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('clone', out: out_io)
    end
  end
end
