# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'git'

# Temporarily source yard-lint from a fork branch that adds the
# Tags/TagSeparator validator (enabled in .yard-lint.yml). Revert to the
# released gem once the validator is merged upstream and published.
# See: https://github.com/mensfeld/yard-lint
gem 'yard-lint', git: 'https://github.com/jcouball/yard-lint', branch: 'feature/tag-separator'
