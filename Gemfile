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

gem 'rubocop', '~> 0.93.1', require: false
gem 'rubocop-performance', '~> 1.8.1', require: false
gem 'rubocop-shopify', '~> 1.0.6', require: false

gem 'liquid', github: 'Shopify/liquid', branch: 'master'
