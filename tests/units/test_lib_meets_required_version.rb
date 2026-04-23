# frozen_string_literal: true

require 'test_helper'

class TestLibMeetsRequiredVersion < Test::Unit::TestCase
  # These tests exercise the deprecated #meets_required_version?, #current_command_version,
  # and #required_command_version methods. Git::Deprecation.stubs(:warn) suppresses the
  # DeprecationException that :raise behavior would otherwise trigger.

  def test_with_supported_command_version
    lib = Git::Lib.new(nil, nil)
    Git::Deprecation.stubs(:warn)
    # Stub git_version so no real git binary is needed
    lib.stubs(:git_version).returns(Git::MINIMUM_GIT_VERSION)
    assert lib.meets_required_version?
  end

  def test_with_old_command_version
    lib = Git::Lib.new(nil, nil)
    Git::Deprecation.stubs(:warn)
    lib.stubs(:git_version).returns(Git::Version.new(1, 28, 0))
    assert !lib.meets_required_version?
  end
end
