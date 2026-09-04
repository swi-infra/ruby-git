# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/stashing'

# Integration-level coverage for the Git::Repository::Stashing facade lives in
# spec/integration/git/repository/stashing_spec.rb (the multi-command orchestration
# in stash_push and stash_store, and Git::StashInfo arguments reaching git) and in
# the command integration specs under spec/integration/git/commands/stash/.

RSpec.describe Git::Repository::Stashing do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  let(:list_command) { instance_double(Git::Commands::Stash::List) }
  let(:push_command) { instance_double(Git::Commands::Stash::Push) }

  # Build a real Git::StashInfo (not an instance_double) so the examples that pass
  # one through a real command class exercise Git::StashInfo#to_s
  def build_stash_info(index:, oid:, message: 'On main: WIP')
    identity = Git::AuthorInfo.new(
      name: 'Jane Doe', email: 'jane@example.com', date: Time.iso8601('2026-01-24T10:30:00-08:00')
    )
    Git::StashInfo.new(
      index: index, name: "stash@{#{index}}", oid: oid, short_oid: oid[0, 7], branch: 'main',
      message: message, author: identity, committer: identity
    )
  end

  let(:stash_info) { build_stash_info(index: 2, oid: 'c' * 40) }

  before do
    allow(Git::Commands::Stash::List).to receive(:new).with(execution_context).and_return(list_command)
    allow(Git::Commands::Stash::Push).to receive(:new).with(execution_context).and_return(push_command)
  end

  describe '#stash_infos' do
    subject(:result) { described_instance.stash_infos }

    let(:list_result) { command_result('fixture') }
    let(:parsed_stashes) { [build_stash_info(index: 0, oid: 'a' * 40), build_stash_info(index: 1, oid: 'b' * 40)] }

    before do
      allow(list_command).to receive(:call).with(no_args).and_return(list_result)
      allow(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes)
    end

    it 'lists the stash entries then parses the output' do
      expect(list_command).to receive(:call).with(no_args).and_return(list_result).ordered
      expect(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes).ordered
      expect(result).to eq(parsed_stashes)
    end

    context 'when there are no stash entries' do
      let(:list_result) { command_result('') }
      let(:parsed_stashes) { [] }

      before { allow(Git::Parsers::Stash).to receive(:parse_list).with('').and_return(parsed_stashes) }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end
  end

  describe '#stash_push' do
    subject(:result) { described_instance.stash_push(*pathspec, **options) }

    let(:pathspec) { [] }
    let(:options) { {} }
    let(:existing_entry) { build_stash_info(index: 0, oid: 'a' * 40, message: 'On main: older work') }
    let(:new_entry) { build_stash_info(index: 0, oid: 'b' * 40) }
    let(:entries_before) { [] }
    let(:entries_after) { [new_entry] }
    let(:push_result) { command_result('Saved working directory and index state On main: WIP') }

    before do
      allow(list_command).to receive(:call).with(no_args).and_return(command_result('before'), command_result('after'))
      allow(Git::Parsers::Stash).to receive(:parse_list).with('before').and_return(entries_before)
      allow(Git::Parsers::Stash).to receive(:parse_list).with('after').and_return(entries_after)
      allow(push_command).to receive(:call).and_return(push_result)
    end

    it 'lists the stash entries, pushes, then lists again to find the new entry' do
      expect(list_command).to receive(:call).with(no_args).and_return(command_result('before')).ordered
      expect(push_command).to receive(:call).with(no_args).and_return(push_result).ordered
      expect(list_command).to receive(:call).with(no_args).and_return(command_result('after')).ordered
      expect(result).to eq(new_entry)
    end

    context 'with a message' do
      let(:options) { { message: 'WIP: feature work' } }

      it 'passes the message to the push command' do
        expect(push_command).to receive(:call).with(message: 'WIP: feature work').and_return(push_result)
        result
      end
    end

    context 'with pathspecs' do
      let(:pathspec) { ['src/a.rb', 'src/b.rb'] }

      it 'passes the pathspecs to the push command' do
        expect(push_command).to receive(:call).with('src/a.rb', 'src/b.rb').and_return(push_result)
        result
      end
    end

    context 'with push options' do
      let(:options) { { keep_index: true, include_untracked: true, quiet: true } }

      it 'forwards the options to the push command' do
        expect(push_command).to(
          receive(:call).with(keep_index: true, include_untracked: true, quiet: true).and_return(push_result)
        )
        result
      end
    end

    context 'when an entry already exists and there are local changes to save' do
      let(:entries_before) { [existing_entry] }
      let(:entries_after) { [new_entry, existing_entry.with(index: 1, name: 'stash@{1}')] }

      it 'returns the new top-of-stack entry' do
        expect(result).to eq(new_entry)
      end
    end

    context 'when there are no local changes to save and the stash list is empty' do
      let(:entries_after) { [] }
      let(:push_result) { command_result('No local changes to save') }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when there are no local changes to save, an entry already exists, and quiet: true hides the message' do
      let(:options) { { quiet: true } }
      let(:entries_before) { [existing_entry] }
      let(:entries_after) { [existing_entry] }
      let(:push_result) { command_result('') }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not list or push' do
        expect(list_command).not_to receive(:call)
        expect(push_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_apply' do
    subject(:result) { described_instance.stash_apply(*args, **options) }

    let(:args) { [] }
    let(:options) { {} }
    let(:apply_command) { instance_double(Git::Commands::Stash::Apply) }
    let(:apply_result) { command_result('HEAD is now at abc1234 Initial commit') }

    before do
      allow(Git::Commands::Stash::Apply).to receive(:new).with(execution_context).and_return(apply_command)
      allow(apply_command).to receive(:call).and_return(apply_result)
    end

    context 'when no stash is given' do
      it 'calls Git::Commands::Stash::Apply#call with nil' do
        expect(apply_command).to receive(:call).with(nil).and_return(apply_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('HEAD is now at abc1234 Initial commit')
      end
    end

    context 'when a string stash reference is given' do
      let(:args) { ['stash@{1}'] }

      it 'calls Git::Commands::Stash::Apply#call with the reference' do
        expect(apply_command).to receive(:call).with('stash@{1}').and_return(apply_result)
        result
      end
    end

    context 'when an integer index is given' do
      let(:args) { [2] }

      it 'calls Git::Commands::Stash::Apply#call with the integer' do
        expect(apply_command).to receive(:call).with(2).and_return(apply_result)
        result
      end
    end

    context 'when a Git::StashInfo is given' do
      let(:args) { [stash_info] }

      # Use the real command class: the arguments DSL calls #to_s on the operand, so
      # this proves git receives the stash@{N} name rather than the object itself
      before do
        allow(Git::Commands::Stash::Apply).to receive(:new).and_call_original
        stub_git_version(execution_context, '99.99.99')
      end

      it 'passes the stash name to git' do
        expect_command_capturing('stash', 'apply', 'stash@{2}').and_return(apply_result)
        result
      end
    end

    context 'with the :index and :quiet options' do
      let(:options) { { index: true, quiet: true } }

      it 'forwards the options to the apply command' do
        expect(apply_command).to receive(:call).with(nil, index: true, quiet: true).and_return(apply_result)
        result
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_pop' do
    subject(:result) { described_instance.stash_pop(*args, **options) }

    let(:args) { [] }
    let(:options) { {} }
    let(:pop_command) { instance_double(Git::Commands::Stash::Pop) }
    let(:pop_result) { command_result('Dropped refs/stash@{0} (abc1234)') }

    before do
      allow(Git::Commands::Stash::Pop).to receive(:new).with(execution_context).and_return(pop_command)
      allow(pop_command).to receive(:call).and_return(pop_result)
    end

    context 'when no stash is given' do
      it 'calls Git::Commands::Stash::Pop#call with nil' do
        expect(pop_command).to receive(:call).with(nil).and_return(pop_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('Dropped refs/stash@{0} (abc1234)')
      end
    end

    context 'when a string stash reference is given' do
      let(:args) { ['stash@{1}'] }

      it 'calls Git::Commands::Stash::Pop#call with the reference' do
        expect(pop_command).to receive(:call).with('stash@{1}').and_return(pop_result)
        result
      end
    end

    context 'when an integer index is given' do
      let(:args) { [1] }

      it 'calls Git::Commands::Stash::Pop#call with the integer' do
        expect(pop_command).to receive(:call).with(1).and_return(pop_result)
        result
      end
    end

    context 'when a Git::StashInfo is given' do
      let(:args) { [stash_info] }

      before do
        allow(Git::Commands::Stash::Pop).to receive(:new).and_call_original
        stub_git_version(execution_context, '99.99.99')
      end

      it 'passes the stash name to git' do
        expect_command_capturing('stash', 'pop', 'stash@{2}').and_return(pop_result)
        result
      end
    end

    context 'with the :index and :quiet options' do
      let(:options) { { index: true, quiet: true } }

      it 'forwards the options to the pop command' do
        expect(pop_command).to receive(:call).with(nil, index: true, quiet: true).and_return(pop_result)
        result
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_drop' do
    subject(:result) { described_instance.stash_drop(*args, **options) }

    let(:args) { [] }
    let(:options) { {} }
    let(:drop_command) { instance_double(Git::Commands::Stash::Drop) }
    let(:drop_result) { command_result('Dropped refs/stash@{0} (abc1234)') }

    before do
      allow(Git::Commands::Stash::Drop).to receive(:new).with(execution_context).and_return(drop_command)
      allow(drop_command).to receive(:call).and_return(drop_result)
    end

    context 'when no stash is given' do
      it 'calls Git::Commands::Stash::Drop#call with nil' do
        expect(drop_command).to receive(:call).with(nil).and_return(drop_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq('Dropped refs/stash@{0} (abc1234)')
      end
    end

    context 'when a string stash reference is given' do
      let(:args) { ['stash@{1}'] }

      it 'calls Git::Commands::Stash::Drop#call with the reference' do
        expect(drop_command).to receive(:call).with('stash@{1}').and_return(drop_result)
        result
      end
    end

    context 'when an integer index is given' do
      let(:args) { [1] }

      it 'calls Git::Commands::Stash::Drop#call with the integer' do
        expect(drop_command).to receive(:call).with(1).and_return(drop_result)
        result
      end
    end

    context 'when a Git::StashInfo is given' do
      let(:args) { [stash_info] }

      before do
        allow(Git::Commands::Stash::Drop).to receive(:new).and_call_original
        stub_git_version(execution_context, '99.99.99')
      end

      it 'passes the stash name to git' do
        expect_command_capturing('stash', 'drop', 'stash@{2}').and_return(drop_result)
        result
      end
    end

    context 'with the :quiet option' do
      let(:options) { { quiet: true } }

      it 'forwards the option to the drop command' do
        expect(drop_command).to receive(:call).with(nil, quiet: true).and_return(drop_result)
        result
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_show' do
    subject(:result) { described_instance.stash_show(*args, **options) }

    let(:args) { [] }
    let(:options) { {} }
    let(:show_command) { instance_double(Git::Commands::Stash::Show) }
    let(:show_result) { command_result(" file.txt | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)") }

    before do
      allow(Git::Commands::Stash::Show).to receive(:new).with(execution_context).and_return(show_command)
      allow(show_command).to receive(:call).and_return(show_result)
    end

    context 'when no stash is given' do
      it 'calls Git::Commands::Stash::Show#call with nil' do
        expect(show_command).to receive(:call).with(nil).and_return(show_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq(" file.txt | 2 +-\n 1 file changed, 1 insertion(+), 1 deletion(-)")
      end
    end

    context 'when a string stash reference is given' do
      let(:args) { ['stash@{1}'] }

      it 'calls Git::Commands::Stash::Show#call with the reference' do
        expect(show_command).to receive(:call).with('stash@{1}').and_return(show_result)
        result
      end
    end

    context 'when an integer index is given' do
      let(:args) { [1] }

      it 'calls Git::Commands::Stash::Show#call with the integer' do
        expect(show_command).to receive(:call).with(1).and_return(show_result)
        result
      end
    end

    context 'when a Git::StashInfo is given' do
      let(:args) { [stash_info] }

      before do
        allow(Git::Commands::Stash::Show).to receive(:new).and_call_original
        stub_git_version(execution_context, '99.99.99')
      end

      it 'passes the stash name to git' do
        expect_command_capturing('stash', 'show', 'stash@{2}').and_return(show_result)
        result
      end
    end

    context 'with show options' do
      let(:options) { { patch: true, include_untracked: true } }

      it 'forwards the options to the show command' do
        expect(show_command).to receive(:call).with(nil, patch: true, include_untracked: true).and_return(show_result)
        result
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_branch' do
    subject(:result) { described_instance.stash_branch('feature', *args) }

    let(:args) { [] }
    let(:branch_command) { instance_double(Git::Commands::Stash::Branch) }
    let(:branch_result) { command_result("Switched to a new branch 'feature'") }

    before do
      allow(Git::Commands::Stash::Branch).to receive(:new).with(execution_context).and_return(branch_command)
      allow(branch_command).to receive(:call).and_return(branch_result)
    end

    context 'when no stash is given' do
      it 'calls Git::Commands::Stash::Branch#call with the branch name and nil' do
        expect(branch_command).to receive(:call).with('feature', nil).and_return(branch_result)
        result
      end

      it 'returns the stdout string' do
        expect(result).to eq("Switched to a new branch 'feature'")
      end
    end

    context 'when a string stash reference is given' do
      let(:args) { ['stash@{1}'] }

      it 'calls Git::Commands::Stash::Branch#call with the branch name and the reference' do
        expect(branch_command).to receive(:call).with('feature', 'stash@{1}').and_return(branch_result)
        result
      end
    end

    context 'when an integer index is given' do
      let(:args) { [1] }

      it 'calls Git::Commands::Stash::Branch#call with the branch name and the integer' do
        expect(branch_command).to receive(:call).with('feature', 1).and_return(branch_result)
        result
      end
    end

    context 'when a Git::StashInfo is given' do
      let(:args) { [stash_info] }

      before do
        allow(Git::Commands::Stash::Branch).to receive(:new).and_call_original
        stub_git_version(execution_context, '99.99.99')
      end

      it 'passes the stash name to git' do
        expect_command_capturing('stash', 'branch', 'feature', 'stash@{2}').and_return(branch_result)
        result
      end
    end
  end

  describe '#stash_create' do
    subject(:result) { described_instance.stash_create(*args) }

    let(:args) { [] }
    let(:create_command) { instance_double(Git::Commands::Stash::Create) }
    let(:create_result) { command_result("#{'d' * 40}\n") }

    before do
      allow(Git::Commands::Stash::Create).to receive(:new).with(execution_context).and_return(create_command)
      allow(create_command).to receive(:call).and_return(create_result)
    end

    context 'when no message is given' do
      it 'calls Git::Commands::Stash::Create#call with nil' do
        expect(create_command).to receive(:call).with(nil).and_return(create_result)
        result
      end

      it 'returns the object id without surrounding whitespace' do
        expect(result).to eq('d' * 40)
      end
    end

    context 'when a message is given' do
      let(:args) { ['WIP: feature work'] }

      it 'calls Git::Commands::Stash::Create#call with the message' do
        expect(create_command).to receive(:call).with('WIP: feature work').and_return(create_result)
        result
      end
    end

    context 'when there are no local changes' do
      let(:create_result) { command_result('') }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#stash_store' do
    subject(:result) { described_instance.stash_store(commit, **options) }

    let(:commit) { 'd' * 40 }
    let(:options) { {} }
    let(:store_command) { instance_double(Git::Commands::Stash::Store) }
    let(:store_result) { command_result('') }
    let(:stored_entry) { build_stash_info(index: 0, oid: commit, message: 'Created via "git stash store".') }

    before do
      allow(Git::Commands::Stash::Store).to receive(:new).with(execution_context).and_return(store_command)
      allow(store_command).to receive(:call).and_return(store_result)
      allow(list_command).to receive(:call).with(no_args).and_return(command_result('fixture'))
      allow(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return([stored_entry])
    end

    it 'stores the commit then lists the stash entries to return the new top entry' do
      expect(store_command).to receive(:call).with(commit).and_return(store_result).ordered
      expect(list_command).to receive(:call).with(no_args).and_return(command_result('fixture')).ordered
      expect(result).to eq(stored_entry)
    end

    context 'with the :message and :quiet options' do
      let(:options) { { message: 'restored work', quiet: true } }

      it 'forwards the options to the store command' do
        expect(store_command).to(
          receive(:call).with(commit, message: 'restored work', quiet: true).and_return(store_result)
        )
        result
      end
    end

    context 'option whitelisting' do
      let(:options) { { bogus: true } }

      it 'raises ArgumentError for an unknown option' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not store or list' do
        expect(store_command).not_to receive(:call)
        expect(list_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  describe '#stash_clear' do
    subject(:result) { described_instance.stash_clear }

    let(:clear_command) { instance_double(Git::Commands::Stash::Clear) }
    let(:clear_result) { command_result('') }

    before do
      allow(Git::Commands::Stash::Clear).to receive(:new).with(execution_context).and_return(clear_command)
      allow(clear_command).to receive(:call).and_return(clear_result)
    end

    it 'calls Git::Commands::Stash::Clear#call with no arguments' do
      expect(clear_command).to receive(:call).with(no_args).and_return(clear_result)
      result
    end

    it 'returns the stdout string' do
      expect(result).to eq('')
    end
  end

  describe '#stashes_all' do
    subject(:result) { described_instance.stashes_all }

    let(:list_result) { command_result('fixture') }
    let(:parsed_stashes) { [] }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(list_command).to receive(:call).with(no_args).and_return(list_result)
      allow(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes)
    end

    it 'emits a deprecation warning pointing at stash_infos' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#stashes_all is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#stash_infos instead.'
      )
      result
    end

    context 'when there are no stash entries' do
      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end

    context 'when there are stash entries with branch-prefixed messages' do
      let(:stash_info_older) { instance_double(Git::StashInfo, message: 'On main: Fix bug') }
      let(:stash_info_newer) { instance_double(Git::StashInfo, message: 'On main: Add feature') }
      # parse_list returns newest-first; stashes_all reverses to oldest-first
      let(:parsed_stashes) { [stash_info_newer, stash_info_older] }

      it 'calls Git::Commands::Stash::List#call with no arguments' do
        expect(list_command).to receive(:call).with(no_args).and_return(list_result)
        result
      end

      it 'passes the command stdout to Git::Parsers::Stash.parse_list' do
        expect(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes)
        result
      end

      it 'returns stash entries in oldest-first order with sequential indices and the branch prefix stripped' do
        expect(result).to eq([[0, 'Fix bug'], [1, 'Add feature']])
      end
    end

    context 'when a stash entry has no branch prefix (custom message)' do
      let(:parsed_stashes) { [instance_double(Git::StashInfo, message: 'custom message')] }

      it 'returns the message unchanged' do
        expect(result).to eq([[0, 'custom message']])
      end
    end

    context 'when a stash entry has a message with an internal colon (e.g. "saving: note")' do
      let(:parsed_stashes) { [instance_double(Git::StashInfo, message: 'On main: saving: note')] }

      it 'strips only the first prefix, keeping subsequent colons in the message' do
        expect(result).to eq([[0, 'saving: note']])
      end
    end
  end

  describe '#stash_save' do
    subject(:result) { described_instance.stash_save('WIP: feature work') }

    let(:push_result) { command_result('Saved working directory and index state On main: WIP: feature work') }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(push_command).to receive(:call).with(message: 'WIP: feature work').and_return(push_result)
    end

    it 'emits a deprecation warning pointing at stash_push' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#stash_save is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#stash_push(message: ...) instead.'
      )
      result
    end

    context 'when there are local changes to save' do
      it 'calls Git::Commands::Stash::Push with the given message' do
        expect(push_command).to receive(:call).with(message: 'WIP: feature work').and_return(push_result)
        result
      end

      it 'returns true' do
        expect(result).to be(true)
      end
    end

    context 'when there are no local changes to save' do
      let(:push_result) { command_result('No local changes to save') }

      it 'returns false' do
        expect(result).to be(false)
      end
    end
  end

  describe '#stash_list' do
    subject(:result) { described_instance.stash_list }

    let(:list_result) { command_result('fixture') }
    let(:parsed_stashes) { [] }

    before do
      allow(Git::Deprecation).to receive(:warn)
      allow(list_command).to receive(:call).with(no_args).and_return(list_result)
      allow(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes)
    end

    it 'emits a deprecation warning pointing at stash_infos' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#stash_list is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#stash_infos instead.'
      )
      result
    end

    context 'when there are stash entries' do
      let(:stash_info_first) { instance_double(Git::StashInfo, name: 'stash@{0}', message: 'On main: WIP') }
      let(:stash_info_second) { instance_double(Git::StashInfo, name: 'stash@{1}', message: 'On main: Fix bug') }
      let(:parsed_stashes) { [stash_info_first, stash_info_second] }

      it 'passes the command stdout to Git::Parsers::Stash.parse_list' do
        expect(Git::Parsers::Stash).to receive(:parse_list).with('fixture').and_return(parsed_stashes)
        result
      end

      it 'returns a newline-joined "stash@{n}: <full message>" string' do
        expect(result).to eq("stash@{0}: On main: WIP\nstash@{1}: On main: Fix bug")
      end
    end

    context 'when there are no stash entries' do
      it 'returns an empty string' do
        expect(result).to eq('')
      end
    end
  end
end
