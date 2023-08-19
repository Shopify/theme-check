# frozen_string_literal: true

guard :minitest do
  watch(%r{^test/(.*)_test.rb$})
  watch(%r{^lib/platformos_check/(.*)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^test/test_helper\.rb$}) { 'test' }
end
