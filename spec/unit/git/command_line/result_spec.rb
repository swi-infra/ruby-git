# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::CommandLine::Result do
  let(:status_double) { double('ProcessExecuter::Result') }

  subject(:result) do
    git_cmd = %w[git version]
    stdout = "git version 2.39.1\n"
    stderr = ''
    described_class.new(git_cmd, status_double, stdout, stderr)
  end

  it 'is aliased as Git::CommandLineResult' do
    expect(Git::CommandLineResult).to be(described_class)
  end

  describe '#initialize / attr_readers' do
    it 'exposes git_cmd' do
      expect(result.git_cmd).to eq(%w[git version])
    end

    it 'exposes status' do
      expect(result.status).to be(status_double)
    end

    it 'exposes stdout' do
      expect(result.stdout).to eq("git version 2.39.1\n")
    end

    it 'exposes stderr' do
      expect(result.stderr).to eq('')
    end
  end
end
