# frozen_string_literal: true

require 'bundler'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Checks that a gem works as users install it, not as the checkout runs it
#
# Builds the gem from its gemspec, installs it with its runtime dependencies into an
# empty gem home, and runs a Ruby script that can see only that gem home. The script
# cannot load the checkout's lib/, the bundle, or any gem installed on the machine, so
# a file the package leaves out or a dependency the gemspec does not declare makes it
# fail.
module InstalledGemCheck
  # Raised when building the gem, installing it, or running the script fails
  class Failed < StandardError; end

  module_function

  # Build, install, and run script against the installed gem
  #
  # Installing fetches the gem's runtime dependencies from its sources, usually
  # rubygems.org.
  #
  # @param gemspec_path [String] the gemspec to build
  # @param script [String] Ruby code to run in the gemspec's directory
  # @return [String] the script's standard output
  # @raise [Failed] if a step fails; the message includes its output
  def run(gemspec_path, script)
    gemspec_path = File.expand_path(gemspec_path)
    Dir.mktmpdir('installed-gem-check') do |tmp_dir|
      gem_home = File.join(tmp_dir, 'gem_home')
      gem_file = File.join(tmp_dir, "#{File.basename(gemspec_path, '.gemspec')}.gem")
      step = Step.new(environment(gem_home), File.dirname(gemspec_path))

      step.run('gem build', gem_command, 'build', gemspec_path, '--output', gem_file)
      step.run('gem install', gem_command, 'install', '--no-document', '--install-dir', gem_home, gem_file)
      step.run('script', RbConfig.ruby, '-e', script)
    end
  end

  # The environment the parent process started with, before Bundler changed it,
  # with the empty gem home as the only gem location
  #
  # Every other variable in ENV is unset so that nothing Bundler added, such as
  # RUBYOPT=-rbundler/setup or BUNDLE_GEMFILE, reaches the child. ENV itself is not
  # changed.
  def environment(gem_home)
    ENV.keys.to_h { |key| [key, nil] }
       .merge(Bundler.unbundled_env)
       .merge('GEM_HOME' => gem_home, 'GEM_PATH' => gem_home)
  end

  # Run the running Ruby's own gem script by path. `ruby -S gem` would search PATH,
  # where a version manager's shim (asdf, rbenv) may be a shell script or belong to a
  # different Ruby.
  def gem_command
    [RbConfig.ruby, File.join(RbConfig::CONFIG['bindir'], 'gem')]
  end

  # Runs one command in a fixed environment and directory
  Step = Struct.new(:env, :dir) do
    def run(name, *command)
      output, error, status = Open3.capture3(env, *command.flatten, chdir: dir)
      return output if status.success?

      raise Failed, "#{name} failed:\n#{output}#{error}"
    end
  end
end
