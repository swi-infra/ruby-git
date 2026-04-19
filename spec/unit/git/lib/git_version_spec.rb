# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Lib do
  describe '#git_version' do
    let(:lib) { described_class.new(nil) }
    let(:version_command) { instance_double(Git::Commands::Version) }

    before do
      # Clear the class-level cache so each test starts fresh
      described_class.clear_git_version_cache

      allow(Git::Commands::Version).to receive(:new).and_return(version_command)
    end

    context 'with standard version output' do
      it 'returns a Git::Version' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.42.1'))
        expect(lib.git_version).to be_a(Git::Version)
      end

      it 'parses the version correctly' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.42.1'))
        expect(lib.git_version).to eq(Git::Version.new(2, 42, 1))
      end
    end

    context 'with platform suffix' do
      it 'strips .windows suffix' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.42.1.windows.1'))
        expect(lib.git_version).to eq(Git::Version.new(2, 42, 1))
      end

      it 'strips .vfs suffix' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.39.2.vfs.0.0'))
        expect(lib.git_version).to eq(Git::Version.new(2, 39, 2))
      end
    end

    context 'with two-segment version' do
      it 'pads to three segments' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.42'))
        expect(lib.git_version).to eq(Git::Version.new(2, 42, 0))
      end
    end

    context 'with unparseable output' do
      it 'raises Git::Error' do
        allow(version_command).to receive(:call).and_return(command_result('not a version'))
        expect { lib.git_version }.to raise_error(Git::Error, /Unable to parse git version/)
      end
    end

    context 'memoization' do
      it 'caches the result' do
        allow(version_command).to receive(:call).and_return(command_result('git version 2.42.1'))
        first_call = lib.git_version
        second_call = lib.git_version
        expect(first_call).to equal(second_call)
        expect(version_command).to have_received(:call).once
      end

      it 'isolates the class-level cache by binary_path' do
        original_binary_path = Git::Base.config.binary_path
        allow(version_command).to receive(:call).and_return(
          command_result('git version 2.42.1'),
          command_result('git version 2.42.2')
        )

        begin
          Git::Base.config.binary_path = '/usr/bin/git-first'
          first_path_version = described_class.new(nil).git_version

          Git::Base.config.binary_path = '/usr/bin/git-second'
          second_path_version = described_class.new(nil).git_version

          Git::Base.config.binary_path = '/usr/bin/git-first'
          cached_first_path_version = described_class.new(nil).git_version

          expect(first_path_version).to eq(Git::Version.new(2, 42, 1))
          expect(second_path_version).to eq(Git::Version.new(2, 42, 2))
          expect(cached_first_path_version).to equal(first_path_version)
          expect(version_command).to have_received(:call).twice
        ensure
          Git::Base.config.binary_path = original_binary_path
          described_class.clear_git_version_cache
        end
      end
    end
  end
end
