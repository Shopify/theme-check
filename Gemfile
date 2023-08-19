# frozen_string_literal: true
source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in platformos-check.gemspec
gemspec

gem 'bundler'
gem 'rake'

group :test do
  gem 'minitest'
  gem 'minitest-focus'
  gem 'mocha'
  gem 'pry-byebug'
end

group :development do
  gem 'guard'
  gem 'guard-minitest'
  gem 'ruby-prof'
  gem 'ruby-prof-flamegraph'
  gem 'solargraph'
end

gem 'rubocop', require: false
gem 'rubocop-performance', require: false
gem 'rubocop-minitest', require: false
gem 'rubocop-rake', require: false
