# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'rbconfig'

RSpec.describe 'Git::Base require behavior', :integration do
  let(:project_root) { File.expand_path('../../..', __dir__) }

  def run_script(script)
    Open3.capture3(
      RbConfig.ruby,
      '-I', File.join(project_root, 'lib'),
      '-e', script,
      chdir: project_root
    )
  end

  it "allows requiring 'git/base' directly and calling Git::Base.bare" do
    script = <<~RUBY
      require 'git/base'
      git = Git::Base.bare(Dir.pwd)
      puts git.class.name
    RUBY

    stdout, stderr, status = run_script(script)

    expect(status.success?).to be(true), stderr
    expect(stdout).to include('Git::Base')
  end

  it "defines Git::ExecutionContext::Global after requiring 'git/base'" do
    script = <<~RUBY
      require 'git/base'
      puts Git::ExecutionContext::Global.name
    RUBY

    stdout, stderr, status = run_script(script)

    expect(status.success?).to be(true), stderr
    expect(stdout.chomp).to eq('Git::ExecutionContext::Global')
  end

  it "defines Git::FailedError after requiring 'git/base'" do
    script = <<~RUBY
      require 'git/base'
      puts Git::FailedError.name
    RUBY

    stdout, stderr, status = run_script(script)

    expect(status.success?).to be(true), stderr
    expect(stdout.chomp).to eq('Git::FailedError')
  end
end
