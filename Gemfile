# frozen_string_literal: true
source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in theme-check.gemspec
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

gem 'rubocop', '~> 1.61.0', require: false
gem 'rubocop-performance', '~> 1.10.2', require: false
gem 'rubocop-shopify', '~> 1.0.7', require: false
gem 'rubocop-minitest', '~> 0.11.0', require: false
gem 'rubocop-rake', '~> 0.5.1', require: false
