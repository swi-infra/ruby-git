# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require_relative '../../../../tasks/support/installed_gem_check'

RSpec.describe InstalledGemCheck do
  describe '.run' do
    subject(:result) { described_class.run(gemspec_path, script) }

    let(:project_dir) { Dir.mktmpdir }
    let(:gemspec_path) { File.join(project_dir, 'probe_gem.gemspec') }
    let(:script) { "require 'probe_gem'\nputs Gem.loaded_specs.fetch('probe_gem').full_name\n" }
    let(:packaged_files) { ['lib/probe_gem.rb'] }
    let(:entry_point) { "module ProbeGem\nend\n" }

    before do
      write_file('lib/probe_gem.rb', entry_point)
      write_file('probe_gem.gemspec', <<~GEMSPEC)
        Gem::Specification.new do |spec|
          spec.name = 'probe_gem'
          spec.version = '1.0.0'
          spec.summary = 'A gem built by the InstalledGemCheck spec'
          spec.authors = ['ruby-git']
          spec.license = 'MIT'
          spec.files = #{packaged_files.inspect}
        end
      GEMSPEC
    end

    after { FileUtils.remove_entry(project_dir) }

    def write_file(relative_path, content)
      path = File.join(project_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    context 'when the installed gem loads' do
      it 'returns the output of the script run against the installed gem' do
        expect(result).to eq("probe_gem-1.0.0\n")
      end
    end

    context 'when the gemspec lists a file that does not exist' do
      let(:packaged_files) { ['lib/probe_gem.rb', 'lib/probe_gem/absent.rb'] }

      it 'raises Failed naming the file gem build could not package' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, %r{lib/probe_gem/absent\.rb})
      end
    end

    context 'when the gem requires a file its gemspec does not package' do
      let(:entry_point) { "require 'probe_gem/unpackaged'\n" }

      before { write_file('lib/probe_gem/unpackaged.rb', "module ProbeGem\nend\n") }

      it 'raises Failed naming the file missing from the installed gem' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, %r{probe_gem/unpackaged})
      end
    end

    # rchardet is a runtime dependency of the git gem, so it is installed in the bundle
    # running this spec. The installed gem fails to load only if the script cannot see
    # the bundle's gems.
    context 'when the gem requires a gem its gemspec does not declare' do
      let(:entry_point) { "require 'rchardet'\n" }

      it 'raises Failed naming the undeclared gem' do
        expect { result }.to raise_error(InstalledGemCheck::Failed, /rchardet/)
      end
    end
  end
end
