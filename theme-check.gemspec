# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "theme_check/version"

Gem::Specification.new do |spec|
  spec.name          = "theme-check"
  spec.version       = ThemeCheck::VERSION
  spec.authors       = ["Marc-André Cournoyer"]
  spec.email         = ["marcandre.cournoyer@shopify.com"]

  spec.summary       = "A Shopify Theme Linter"
  spec.homepage      = "https://github.com/Shopify/theme-check"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    # Load all files tracked in git except files in test directory
    # Include untracked files in liquid documentation folder
    %x{git ls-files -z}.split("\x0").reject { |f| f.match(%r{^test/}) } + Dir['data/shopify_liquid/documentation/**']
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency('liquid', '>= 5.4.0')
  spec.add_dependency('nokogiri', '>= 1.12')
  spec.add_dependency('parser', '~> 3')
end
