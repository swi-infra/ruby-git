# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::CommandLine::Base do
  let(:env) { {} }
  let(:binary_path) { '/usr/bin/git' }
  let(:global_opts) { [] }
  let(:logger) { Logger.new(nil) }

  subject(:base) { described_class.new(env, binary_path, global_opts, logger) }

  describe '#run' do
    it 'raises NotImplementedError' do
      expect { base.run('version') }.to raise_error(NotImplementedError)
    end
  end

  describe '#initialize / attr_readers' do
    it 'exposes env' do
      expect(base.env).to eq(env)
    end

    it 'exposes binary_path' do
      expect(base.binary_path).to eq(binary_path)
    end

    it 'exposes global_opts' do
      expect(base.global_opts).to eq(global_opts)
    end

    it 'exposes logger' do
      expect(base.logger).to eq(logger)
    end
  end
end
