# frozen_string_literal: true

require 'test/unit'

# Tests Git::URL.clone_to
#
class TestURLCloneTo < Test::Unit::TestCase
  def test_clone_to_full_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_path = url_data[:expected_path]
      actual_path = Git::URL.clone_to(url)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  def test_clone_to_bare_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      expected_path = url_data[:expected_bare_path]
      actual_path = Git::URL.clone_to(url, bare: true)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  def test_clone_to_mirror_repo
    GIT_URLS.each do |url_data|
      url = url_data[:url]
      # The expected_path is the same for bare and mirror repos
      expected_path = url_data[:expected_bare_path]
      actual_path = Git::URL.clone_to(url, mirror: true)
      assert_equal(
        expected_path, actual_path,
        "Failed to determine the clone path for URL '#{url}' correctly"
      )
    end
  end

  GIT_URLS = [
    {
      url: 'https://github.com/org/repo',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    },
    {
      url: 'https://github.com/org/repo.git',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    },
    {
      url: 'https://git.mydomain.com/org/repo/.git',
      expected_path: 'repo',
      expected_bare_path: 'repo.git'
    }
  ].freeze
end
