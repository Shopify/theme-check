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

desc "Create a new check"
task :new_check, [:name] do |_t, args|
  require "theme_check/string_helpers"
  class_name = args.name
  base_name = ThemeCheck::StringHelpers.underscore(class_name)
  code_source = "lib/theme_check/checks/#{base_name}.rb"
  doc_source = "docs/checks/#{base_name}.md"
  test_source = "test/checks/#{base_name}_test.rb"
  erb(
    "lib/theme_check/checks/TEMPLATE.rb.erb", code_source,
    class_name: class_name,
  )
  erb(
    "test/checks/TEMPLATE.rb.erb", test_source,
    class_name: class_name,
  )
  erb(
    "docs/checks/TEMPLATE.md.erb", doc_source,
    class_name: class_name,
    code_source: code_source,
    doc_source: doc_source,
  )
  sh "bundle exec ruby -Itest #{test_source}"
end

def erb(file, to, **args)
  require "erb"
  File.write(to, ERB.new(File.read(file)).result_with_hash(args))
  puts "Generated #{to}"
end
