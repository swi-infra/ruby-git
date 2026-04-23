# frozen_string_literal: true

require 'test_helper'

class TestLibMeetsRequiredVersion < Test::Unit::TestCase
  # These tests exercise the deprecated #meets_required_version?, #current_command_version,
  # and #required_command_version methods. Git::Deprecation.stubs(:warn) suppresses the
  # DeprecationException that :raise behavior would otherwise trigger.

  def test_with_supported_command_version
    lib = Git::Lib.new(nil, nil)
    Git::Deprecation.stubs(:warn)
    # Stub the private helper so no real git binary is needed
    lib.define_singleton_method(:fetch_current_version_array) { Git::MINIMUM_GIT_VERSION.to_a }
    assert lib.meets_required_version?
  end

  def test_with_old_command_version
    lib = Git::Lib.new(nil, nil)
    Git::Deprecation.stubs(:warn)
    lib.define_singleton_method(:fetch_current_version_array) { [1, 28] }
    assert !lib.meets_required_version?
  end

  def test_parse_version
    lib = Git::Lib.new(nil, nil)

    versions_to_test = [
      { version_string: 'git version 2.1', expected_result: [2, 1, 0] },
      { version_string: 'git version 2.28.4', expected_result: [2, 28, 4] },
      { version_string: 'git version 2.32.GIT', expected_result: [2, 32, 0] }
    ]

    lib.instance_variable_set(:@next_version_index, 0)

    lib.define_singleton_method(:command_capturing) do |cmd, *_opts, **_kwargs|
      raise ArgumentError unless cmd == 'version'

      version_string = versions_to_test[@next_version_index][:version_string]
      @next_version_index += 1
      status = Struct.new(:success?, :exitstatus).new(true, 0)
      Git::CommandLineResult.new(['git', cmd], status, version_string, '')
    end

    lib.define_singleton_method(:next_version_index) { @next_version_index }

    Git::Deprecation.stubs(:warn)

    expected_version = versions_to_test[lib.next_version_index][:expected_result]
    actual_version = lib.current_command_version
    assert_equal(expected_version, actual_version)

    expected_version = versions_to_test[lib.next_version_index][:expected_result]
    actual_version = lib.current_command_version
    assert_equal(expected_version, actual_version)
  end
end
