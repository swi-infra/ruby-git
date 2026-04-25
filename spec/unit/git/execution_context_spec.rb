# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::ExecutionContext do
  # Create a minimal concrete subclass for testing base-class behaviour.
  # The abstract env_overrides / global_opts raise NotImplementedError in the
  # base, so we need a real implementation to exercise command_capturing etc.
  let(:concrete_class) do
    Class.new(described_class) do
      private

      def env_overrides(**additional_overrides)
        { 'LC_ALL' => 'en_US.UTF-8' }.merge(additional_overrides)
      end

      def global_opts
        []
      end
    end
  end

  describe 'constants' do
    it 'defines COMMAND_CAPTURING_ARG_DEFAULTS' do
      expect(described_class::COMMAND_CAPTURING_ARG_DEFAULTS).to be_a(Hash)
      expect(described_class::COMMAND_CAPTURING_ARG_DEFAULTS).to include(:normalize, :chomp, :raise_on_failure)
    end

    it 'defines COMMAND_STREAMING_ARG_DEFAULTS' do
      expect(described_class::COMMAND_STREAMING_ARG_DEFAULTS).to be_a(Hash)
      expect(described_class::COMMAND_STREAMING_ARG_DEFAULTS).to include(:raise_on_failure)
    end

    it 'defines STATIC_GLOBAL_OPTS' do
      expect(described_class::STATIC_GLOBAL_OPTS).to be_a(Array)
      expect(described_class::STATIC_GLOBAL_OPTS).to include('-c', 'core.quotePath=true')
    end
  end

  describe 'abstract interface' do
    let(:context) { described_class.new }

    it 'raises NotImplementedError when env_overrides is not implemented' do
      expect { context.send(:env_overrides) }
        .to raise_error(NotImplementedError, /must implement #env_overrides/)
    end

    it 'raises NotImplementedError when global_opts is not implemented' do
      expect { context.send(:global_opts) }
        .to raise_error(NotImplementedError, /must implement #global_opts/)
    end
  end

  describe '#command_capturing' do
    let(:context) { concrete_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Capturing) }
    let(:result) { command_result('output') }

    before do
      allow(context).to receive(:command_line_capturing).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_capturing.run with defaults' do
      expect(command_line_double).to receive(:run)
        .with('version', hash_including(raise_on_failure: true, normalize: true, chomp: true))
        .and_return(result)
      context.command_capturing('version')
    end

    it 'raises ArgumentError for unknown option keys' do
      expect { context.command_capturing('version', bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end

  describe '#command_streaming' do
    let(:context) { concrete_class.new }
    let(:command_line_double) { instance_double(Git::CommandLine::Streaming) }
    let(:result) { command_result('') }

    before do
      allow(context).to receive(:command_line_streaming).and_return(command_line_double)
      allow(Git::Base).to receive_message_chain(:config, :timeout).and_return(nil)
    end

    it 'delegates to command_line_streaming.run' do
      expect(command_line_double).to receive(:run)
        .with('cat-file', '--batch', hash_including(raise_on_failure: true, timeout: nil))
        .and_return(result)
      context.command_streaming('cat-file', '--batch')
    end

    it 'raises ArgumentError for unknown option keys' do
      expect { context.command_streaming('cat-file', bogus: true) }
        .to raise_error(ArgumentError, /Unknown options: bogus/)
    end
  end
end
