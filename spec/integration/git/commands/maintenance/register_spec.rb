# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/maintenance/register'

# GIT_CONFIG_GLOBAL (used for global config isolation) requires git 2.32.0,
# so these integration tests require 2.32.0 even though the command itself supports 2.30.0.
RSpec.describe Git::Commands::Maintenance::Register, :integration,
               skip: unless_git('2.32.0', 'git maintenance register') do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  # Redirect all global config writes to a temp file to avoid polluting ~/.gitconfig.
  # --config-file is also passed to the command itself to redirect the maintenance.repo write.
  let(:global_config) { Tempfile.new(['maintenance_global', '.conf']) }
  let(:isolated_env) { { 'GIT_CONFIG_GLOBAL' => global_config.path } }

  after do
    global_config.close
    global_config.unlink
  end

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call(config_file: global_config.path, env: isolated_env)

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit code 0' do
        result = command.call(config_file: global_config.path, env: isolated_env)

        expect(result.status.exitstatus).to eq(0)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when not in a git repository' do
        FileUtils.rm_rf(File.join(repo_dir, '.git'))

        expect { command.call(config_file: global_config.path, env: isolated_env) }.to raise_error(Git::FailedError)
      end
    end
  end
end
