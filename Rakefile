# frozen_string_literal: true
require "rake/testtask"
require "rubocop/rake_task"
require "bundler/gem_tasks"

namespace :tests do
  task all: [:in_memory, :file_system]

  Rake::TestTask.new(:suite) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"]
  end

  desc("Runs the tests with InMemoryStorage")
  task :in_memory do
    ENV["THEME_STORAGE"] = 'InMemoryStorage'
    puts "Running tests with #{ENV['THEME_STORAGE']}"
    Rake::Task['tests:suite'].execute
  end

  desc("Runs the tests with FileSystemStorage")
  task :file_system do
    ENV["THEME_STORAGE"] = 'FileSystemStorage'
    puts "Running tests with #{ENV['THEME_STORAGE']}"
    Rake::Task['tests:suite'].execute
  end
end

task(test: 'tests:all')

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

desc("Update files in the repo to match new version")
task :prerelease, [:version] do |_t, args|
  require 'theme_check/releaser'
  ThemeCheck::Releaser.new.release(args.version)
end
