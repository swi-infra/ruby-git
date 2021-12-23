#!/usr/bin/env ruby
# encoding: utf-8

require File.dirname(__FILE__) + '/../test_helper'

# Test diff when the file path has to be quoted according to core.quotePath
# See https://git-scm.com/docs/git-config#Documentation/git-config.txt-corequotePath
# See https://www.jvt.me/posts/2020/06/23/byte-array-to-string-ruby/
#
class TestUnescapePath < Test::Unit::TestCase
  def test_simple_path
    path = 'my_other_file'
    expected_unescaped_path = 'my_other_file'
    assert_equal(expected_unescaped_path, Git::Lib.unescape_path(path))
  end

  def test_unicode_path
    path = 'my_other_file_\\342\\230\\240'
    expected_unescaped_path = 'my_other_file_☠'
    assert_equal(expected_unescaped_path, Git::Lib.unescape_path(path))
  end

  def test_single_char_escapes
    Git::Lib::UNESCAPES.each_pair do |escape_char, expected_char|
      path = "\\#{escape_char}"
      assert_equal(expected_char.chr, Git::Lib.unescape_path(path))
    end
  end

  def test_compound_escape
    path = "my_other_file_\\\"\\342\\230\\240\\n\\\""
    expected_unescaped_path = 'my_other_file_"☠' + "\n" + '"'
    assert_equal(expected_unescaped_path, Git::Lib.unescape_path(path))
  end
end
