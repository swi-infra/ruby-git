# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/pull'

RSpec.describe Git::Commands::Pull do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  describe '#call' do
    context 'with no arguments' do
      it 'runs git pull with no-edit and no positional arguments' do
        expected_result = command_result
        expect_command_capturing('pull', '--no-edit').and_return(expected_result)

        result = command.call

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository argument' do
      it 'adds -- and the repository after options' do
        expected_result = command_result
        expect_command_capturing('pull', '--no-edit', '--', 'origin').and_return(expected_result)

        result = command.call('origin')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository and refspec' do
      it 'adds -- and then repository and refspec' do
        expected_result = command_result
        expect_command_capturing('pull', '--no-edit', '--', 'origin', 'main').and_return(expected_result)

        result = command.call('origin', 'main')

        expect(result).to eq(expected_result)
      end
    end

    context 'with a repository and multiple refspecs' do
      it 'adds -- and then repository and all refspecs' do
        expected_result = command_result
        expect_command_capturing('pull', '--no-edit', '--', 'origin', 'main', 'develop').and_return(expected_result)

        result = command.call('origin', 'main', 'develop')

        expect(result).to eq(expected_result)
      end
    end

    context 'with the :quiet option' do
      it 'adds --quiet to the command line' do
        expect_command_capturing('pull', '--no-edit', '--quiet').and_return(command_result)

        command.call(quiet: true)
      end

      it 'supports the :q alias' do
        expect_command_capturing('pull', '--no-edit', '--quiet').and_return(command_result)

        command.call(q: true)
      end
    end

    context 'with the :verbose option' do
      it 'adds --verbose to the command line' do
        expect_command_capturing('pull', '--no-edit', '--verbose').and_return(command_result)

        command.call(verbose: true)
      end

      it 'supports the :v alias' do
        expect_command_capturing('pull', '--no-edit', '--verbose').and_return(command_result)

        command.call(v: true)
      end
    end

    context 'with the :progress option' do
      it 'adds --progress to the command line' do
        expect_command_capturing('pull', '--no-edit', '--progress').and_return(command_result)

        command.call(progress: true)
      end
    end

    context 'with the :recurse_submodules option' do
      it 'adds --recurse-submodules when true' do
        expect_command_capturing('pull', '--no-edit', '--recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: true)
      end

      it 'adds --no-recurse-submodules when false' do
        expect_command_capturing('pull', '--no-edit', '--no-recurse-submodules').and_return(command_result)

        command.call(recurse_submodules: false)
      end

      it 'adds --recurse-submodules=<value> when given a string' do
        expect_command_capturing('pull', '--no-edit', '--recurse-submodules=on-demand').and_return(command_result)

        command.call(recurse_submodules: 'on-demand')
      end
    end

    context 'with the :commit option' do
      it 'adds --commit when true' do
        expect_command_capturing('pull', '--no-edit', '--commit').and_return(command_result)

        command.call(commit: true)
      end

      it 'adds --no-commit when false' do
        expect_command_capturing('pull', '--no-edit', '--no-commit').and_return(command_result)

        command.call(commit: false)
      end
    end

    context 'with the :cleanup option' do
      it 'adds --cleanup=<mode> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--cleanup=strip').and_return(command_result)

        command.call(cleanup: 'strip')
      end
    end

    context 'with the :ff option' do
      it 'adds --ff when true' do
        expect_command_capturing('pull', '--no-edit', '--ff').and_return(command_result)

        command.call(ff: true)
      end

      it 'adds --no-ff when false' do
        expect_command_capturing('pull', '--no-edit', '--no-ff').and_return(command_result)

        command.call(ff: false)
      end
    end

    context 'with the :ff_only option' do
      it 'adds --ff-only to the command line' do
        expect_command_capturing('pull', '--no-edit', '--ff-only').and_return(command_result)

        command.call(ff_only: true)
      end
    end

    context 'with the :log option' do
      it 'adds --log when true' do
        expect_command_capturing('pull', '--no-edit', '--log').and_return(command_result)

        command.call(log: true)
      end

      it 'adds --no-log when false' do
        expect_command_capturing('pull', '--no-edit', '--no-log').and_return(command_result)

        command.call(log: false)
      end

      it 'adds --log=<n> when given an integer' do
        expect_command_capturing('pull', '--no-edit', '--log=5').and_return(command_result)

        command.call(log: 5)
      end
    end

    context 'with the :squash option' do
      it 'adds --squash when true' do
        expect_command_capturing('pull', '--no-edit', '--squash').and_return(command_result)

        command.call(squash: true)
      end

      it 'adds --no-squash when false' do
        expect_command_capturing('pull', '--no-edit', '--no-squash').and_return(command_result)

        command.call(squash: false)
      end
    end

    context 'with the :verify option' do
      it 'adds --verify when true' do
        expect_command_capturing('pull', '--no-edit', '--verify').and_return(command_result)

        command.call(verify: true)
      end

      it 'adds --no-verify when false' do
        expect_command_capturing('pull', '--no-edit', '--no-verify').and_return(command_result)

        command.call(verify: false)
      end
    end

    context 'with the :strategy option' do
      it 'adds --strategy <name> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--strategy', 'ort').and_return(command_result)

        command.call(strategy: 'ort')
      end

      it 'supports the :s alias' do
        expect_command_capturing('pull', '--no-edit', '--strategy', 'recursive').and_return(command_result)

        command.call(s: 'recursive')
      end
    end

    context 'with the :strategy_option option' do
      it 'adds -X <option> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--strategy-option', 'theirs').and_return(command_result)

        command.call(strategy_option: 'theirs')
      end

      it 'repeats the flag for multiple values' do
        expect_command_capturing(
          'pull', '--no-edit', '--strategy-option', 'theirs', '--strategy-option', 'patience'
        ).and_return(command_result)

        command.call(strategy_option: %w[theirs patience])
      end

      it 'supports the :X alias' do
        expect_command_capturing('pull', '--no-edit', '--strategy-option', 'ours').and_return(command_result)

        command.call(X: 'ours')
      end
    end

    context 'with the :verify_signatures option' do
      it 'adds --verify-signatures when true' do
        expect_command_capturing('pull', '--no-edit', '--verify-signatures').and_return(command_result)

        command.call(verify_signatures: true)
      end

      it 'adds --no-verify-signatures when false' do
        expect_command_capturing('pull', '--no-edit', '--no-verify-signatures').and_return(command_result)

        command.call(verify_signatures: false)
      end
    end

    context 'with the :summary option' do
      it 'adds --summary when true' do
        expect_command_capturing('pull', '--no-edit', '--summary').and_return(command_result)

        command.call(summary: true)
      end

      it 'adds --no-summary when false' do
        expect_command_capturing('pull', '--no-edit', '--no-summary').and_return(command_result)

        command.call(summary: false)
      end
    end

    context 'with the :allow_unrelated_histories option' do
      it 'adds --allow-unrelated-histories to the command line' do
        expect_command_capturing('pull', '--no-edit', '--allow-unrelated-histories').and_return(command_result)

        command.call(allow_unrelated_histories: true)
      end
    end

    context 'with the :rebase option' do
      it 'adds --rebase when true' do
        expect_command_capturing('pull', '--no-edit', '--rebase').and_return(command_result)

        command.call(rebase: true)
      end

      it 'adds --no-rebase when false' do
        expect_command_capturing('pull', '--no-edit', '--no-rebase').and_return(command_result)

        command.call(rebase: false)
      end

      it 'adds --rebase=<mode> when given a string' do
        expect_command_capturing('pull', '--no-edit', '--rebase=merges').and_return(command_result)

        command.call(rebase: 'merges')
      end

      it 'supports the :r alias' do
        expect_command_capturing('pull', '--no-edit', '--rebase').and_return(command_result)

        command.call(r: true)
      end
    end

    context 'with the :autostash option' do
      it 'adds --autostash when true' do
        expect_command_capturing('pull', '--no-edit', '--autostash').and_return(command_result)

        command.call(autostash: true)
      end

      it 'adds --no-autostash when false' do
        expect_command_capturing('pull', '--no-edit', '--no-autostash').and_return(command_result)

        command.call(autostash: false)
      end
    end

    context 'with the :signoff option' do
      it 'adds --signoff when true' do
        expect_command_capturing('pull', '--no-edit', '--signoff').and_return(command_result)

        command.call(signoff: true)
      end

      it 'adds --no-signoff when false' do
        expect_command_capturing('pull', '--no-edit', '--no-signoff').and_return(command_result)

        command.call(signoff: false)
      end
    end

    context 'with the :stat option' do
      it 'adds --stat to the command line' do
        expect_command_capturing('pull', '--no-edit', '--stat').and_return(command_result)

        command.call(stat: true)
      end
    end

    context 'with the :no_stat option' do
      it 'adds --no-stat to the command line' do
        expect_command_capturing('pull', '--no-edit', '--no-stat').and_return(command_result)

        command.call(no_stat: true)
      end

      it 'supports the :n alias' do
        expect_command_capturing('pull', '--no-edit', '--no-stat').and_return(command_result)

        command.call(n: true)
      end
    end

    context 'with the :gpg_sign option' do
      it 'adds --gpg-sign when true' do
        expect_command_capturing('pull', '--no-edit', '--gpg-sign').and_return(command_result)

        command.call(gpg_sign: true)
      end

      it 'adds --no-gpg-sign when false' do
        expect_command_capturing('pull', '--no-edit', '--no-gpg-sign').and_return(command_result)

        command.call(gpg_sign: false)
      end

      it 'adds --gpg-sign=<keyid> when given a string' do
        expect_command_capturing('pull', '--no-edit', '--gpg-sign=ABCDEF').and_return(command_result)

        command.call(gpg_sign: 'ABCDEF')
      end

      it 'supports the :S alias' do
        expect_command_capturing('pull', '--no-edit', '--gpg-sign').and_return(command_result)

        command.call(S: true)
      end
    end

    context 'with the :all option' do
      it 'adds --all to the command line' do
        expect_command_capturing('pull', '--no-edit', '--all').and_return(command_result)

        command.call(all: true)
      end
    end

    context 'with the :append option' do
      it 'adds --append to the command line' do
        expect_command_capturing('pull', '--no-edit', '--append').and_return(command_result)

        command.call(append: true)
      end

      it 'supports the :a alias' do
        expect_command_capturing('pull', '--no-edit', '--append').and_return(command_result)

        command.call(a: true)
      end
    end

    context 'with the :atomic option' do
      it 'adds --atomic to the command line' do
        expect_command_capturing('pull', '--no-edit', '--atomic').and_return(command_result)

        command.call(atomic: true)
      end
    end

    context 'with the :depth option' do
      it 'adds --depth <n> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--depth', '5').and_return(command_result)

        command.call(depth: '5')
      end
    end

    context 'with the :deepen option' do
      it 'adds --deepen <n> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--deepen', '3').and_return(command_result)

        command.call(deepen: '3')
      end
    end

    context 'with the :shallow_since option' do
      it 'adds --shallow-since=<date> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--shallow-since=2024-01-01').and_return(command_result)

        command.call(shallow_since: '2024-01-01')
      end
    end

    context 'with the :shallow_exclude option' do
      it 'adds --shallow-exclude=<ref> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--shallow-exclude=origin/main').and_return(command_result)

        command.call(shallow_exclude: 'origin/main')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--no-edit', '--shallow-exclude=origin/main', '--shallow-exclude=origin/dev'
        ).and_return(command_result)

        command.call(shallow_exclude: %w[origin/main origin/dev])
      end
    end

    context 'with the :unshallow option' do
      it 'adds --unshallow to the command line' do
        expect_command_capturing('pull', '--no-edit', '--unshallow').and_return(command_result)

        command.call(unshallow: true)
      end
    end

    context 'with the :update_shallow option' do
      it 'adds --update-shallow to the command line' do
        expect_command_capturing('pull', '--no-edit', '--update-shallow').and_return(command_result)

        command.call(update_shallow: true)
      end
    end

    context 'with the :negotiation_tip option' do
      it 'adds --negotiation-tip=<commit> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--negotiation-tip=abc1234').and_return(command_result)

        command.call(negotiation_tip: 'abc1234')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--no-edit', '--negotiation-tip=abc1234', '--negotiation-tip=def5678'
        ).and_return(command_result)

        command.call(negotiation_tip: %w[abc1234 def5678])
      end
    end

    context 'with the :negotiate_only option' do
      it 'adds --negotiate-only to the command line' do
        expect_command_capturing('pull', '--no-edit', '--negotiate-only').and_return(command_result)

        command.call(negotiate_only: true)
      end
    end

    context 'with the :dry_run option' do
      it 'adds --dry-run to the command line' do
        expect_command_capturing('pull', '--no-edit', '--dry-run').and_return(command_result)

        command.call(dry_run: true)
      end
    end

    context 'with the :prefetch option' do
      it 'adds --prefetch to the command line' do
        expect_command_capturing('pull', '--no-edit', '--prefetch').and_return(command_result)

        command.call(prefetch: true)
      end
    end

    context 'with the :force option' do
      it 'adds --force to the command line' do
        expect_command_capturing('pull', '--no-edit', '--force').and_return(command_result)

        command.call(force: true)
      end

      it 'supports the :f alias' do
        expect_command_capturing('pull', '--no-edit', '--force').and_return(command_result)

        command.call(f: true)
      end
    end

    context 'with the :keep option' do
      it 'adds --keep to the command line' do
        expect_command_capturing('pull', '--no-edit', '--keep').and_return(command_result)

        command.call(keep: true)
      end

      it 'supports the :k alias' do
        expect_command_capturing('pull', '--no-edit', '--keep').and_return(command_result)

        command.call(k: true)
      end
    end

    context 'with the :prune option' do
      it 'adds --prune to the command line' do
        expect_command_capturing('pull', '--no-edit', '--prune').and_return(command_result)

        command.call(prune: true)
      end

      it 'supports the :p alias' do
        expect_command_capturing('pull', '--no-edit', '--prune').and_return(command_result)

        command.call(p: true)
      end
    end

    context 'with the :tags option' do
      it 'adds --tags when true' do
        expect_command_capturing('pull', '--no-edit', '--tags').and_return(command_result)

        command.call(tags: true)
      end

      it 'adds --no-tags when false' do
        expect_command_capturing('pull', '--no-edit', '--no-tags').and_return(command_result)

        command.call(tags: false)
      end

      it 'supports the :t alias' do
        expect_command_capturing('pull', '--no-edit', '--tags').and_return(command_result)

        command.call(t: true)
      end
    end

    context 'with the :jobs option' do
      it 'adds --jobs <n> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--jobs', '4').and_return(command_result)

        command.call(jobs: '4')
      end

      it 'supports the :j alias' do
        expect_command_capturing('pull', '--no-edit', '--jobs', '2').and_return(command_result)

        command.call(j: '2')
      end
    end

    context 'with the :set_upstream option' do
      it 'adds --set-upstream to the command line' do
        expect_command_capturing('pull', '--no-edit', '--set-upstream').and_return(command_result)

        command.call(set_upstream: true)
      end
    end

    context 'with the :upload_pack option' do
      it 'adds --upload-pack <path> to the command line' do
        expect_command_capturing(
          'pull', '--no-edit', '--upload-pack', '/usr/bin/git-upload-pack'
        ).and_return(command_result)

        command.call(upload_pack: '/usr/bin/git-upload-pack')
      end
    end

    context 'with the :server_option option' do
      it 'adds --server-option=<value> to the command line' do
        expect_command_capturing('pull', '--no-edit', '--server-option=custom').and_return(command_result)

        command.call(server_option: 'custom')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--no-edit', '--server-option=option1', '--server-option=option2'
        ).and_return(command_result)

        command.call(server_option: %w[option1 option2])
      end

      it 'supports the :o alias' do
        expect_command_capturing('pull', '--no-edit', '--server-option=custom').and_return(command_result)

        command.call(o: 'custom')
      end
    end

    context 'with the :show_forced_updates option' do
      it 'adds --show-forced-updates when true' do
        expect_command_capturing('pull', '--no-edit', '--show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: true)
      end

      it 'adds --no-show-forced-updates when false' do
        expect_command_capturing('pull', '--no-edit', '--no-show-forced-updates').and_return(command_result)

        command.call(show_forced_updates: false)
      end
    end

    context 'with the :refmap option' do
      it 'adds --refmap=<refspec> to the command line' do
        expect_command_capturing(
          'pull', '--no-edit', '--refmap=+refs/heads/*:refs/remotes/origin/*'
        ).and_return(command_result)

        command.call(refmap: '+refs/heads/*:refs/remotes/origin/*')
      end

      it 'repeats the option for multiple values' do
        expect_command_capturing(
          'pull', '--no-edit', '--refmap=+refs/heads/*:refs/remotes/origin/*',
          '--refmap=+refs/tags/*:refs/tags/*'
        ).and_return(command_result)

        command.call(refmap: ['+refs/heads/*:refs/remotes/origin/*', '+refs/tags/*:refs/tags/*'])
      end
    end

    context 'with the :ipv4 option' do
      it 'adds --ipv4 to the command line' do
        expect_command_capturing('pull', '--no-edit', '--ipv4').and_return(command_result)

        command.call(ipv4: true)
      end
    end

    context 'with the :ipv6 option' do
      it 'adds --ipv6 to the command line' do
        expect_command_capturing('pull', '--no-edit', '--ipv6').and_return(command_result)

        command.call(ipv6: true)
      end
    end

    context 'with the :timeout execution option' do
      it 'passes the timeout to command_capturing' do
        expect_command_capturing('pull', '--no-edit', timeout: 30).and_return(command_result)

        command.call(timeout: 30)
      end
    end

    context 'with combined options and positional arguments' do
      it 'places flags before -- and positional args after' do
        expect_command_capturing(
          'pull', '--no-edit', '--allow-unrelated-histories', '--', 'origin', 'feature'
        ).and_return(command_result)

        command.call('origin', 'feature', allow_unrelated_histories: true)
      end
    end

    context 'with an unsupported option' do
      it 'raises ArgumentError' do
        expect { command.call(bogus_option: true) }.to raise_error(ArgumentError)
      end
    end
  end
end
