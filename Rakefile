# frozen_string_literal: true
require "rake/testtask"
require "rubocop/rake_task"
require "bundler/gem_tasks"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

task default: [:test, :rubocop]

namespace :package do
  require 'theme_check/packager'

  task all: [:homebrew]

  desc("Builds a Homebrew package of the CLI")
  task :homebrew do
    ThemeCheck::Packager.new.build_homebrew
  end
end

desc("Builds all distribution packages of the CLI")
task(package: 'package:all')
