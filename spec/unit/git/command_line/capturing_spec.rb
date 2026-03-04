# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::CommandLine::Capturing do
  let(:env) { {} }
  let(:binary_path) { 'git' }
  let(:global_opts) { [] }
  let(:logger) { Logger.new(nil) }

  def mock_result(**overrides)
    default_options = {
      command: %w[git status],
      stdout: '',
      stderr: '',
      success?: true,
      signaled?: false,
      timed_out?: false
    }

    double('ProcessExecuter::ResultWithCapture', default_options.merge(overrides))
  end

  subject(:capturing) do
    described_class.new(env, binary_path, global_opts, logger)
  end

  describe '#run' do
    context 'with raise_on_failure option' do
      before do
        mocked_result = mock_result(command: %w[git status], stderr: 'fatal: not a git repository', success?: false)
        allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
      end

      context 'when raise_on_failure is true (default)' do
        it 'raises FailedError on non-zero exit status' do
          expect do
            capturing.run('status')
          end.to raise_error(Git::FailedError)
        end
      end

      context 'when raise_on_failure is false' do
        it 'returns CommandLineResult on non-zero exit status without raising' do
          result = capturing.run('status', raise_on_failure: false)

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.status.success?).to be false
        end

        context 'when command succeeds' do
          before do
            mocked_result = mock_result(success?: true)
            allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
          end

          it 'returns CommandLineResult on success' do
            result = capturing.run('--version', raise_on_failure: false)

            expect(result).to be_a(Git::CommandLineResult)
            expect(result.status.success?).to be true
          end
        end
      end

      context 'timeout and signal errors are always raised' do
        context 'when command times out' do
          before do
            mocked_result = mock_result(success?: false, timed_out?: true)
            allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
          end

          it 'raises TimeoutError even with raise_on_failure: false' do
            expect do
              capturing.run('status', raise_on_failure: false, timeout: 1)
            end.to raise_error(Git::TimeoutError)
          end
        end

        context 'when command is signaled' do
          before do
            mocked_result = mock_result(success?: false, signaled?: true)
            allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
          end

          it 'raises SignaledError even with raise_on_failure: false' do
            expect do
              capturing.run('status', raise_on_failure: false)
            end.to raise_error(Git::SignaledError)
          end
        end
      end
    end

    context 'when command succeeds' do
      before do
        mocked_result = mock_result(command: %w[git version], stdout: "git version 2.39.1\n", success?: true)
        allow(ProcessExecuter).to receive(:run_with_capture).and_return(mocked_result)
      end

      it 'returns a Git::CommandLineResult' do
        result = capturing.run('version')

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns stdout from the result' do
        result = capturing.run('version')

        expect(result.stdout).to eq("git version 2.39.1\n")
      end

      context 'with chomp: true' do
        it 'chomps the stdout output' do
          result = capturing.run('version', chomp: true)

          expect(result.stdout).to eq('git version 2.39.1')
        end
      end
    end

    context 'when an unknown option is passed' do
      it 'raises ArgumentError' do
        expect do
          capturing.run('status', unknown_option: true)
        end.to raise_error(ArgumentError, /Unknown options: unknown_option/)
      end
    end
  end
end
