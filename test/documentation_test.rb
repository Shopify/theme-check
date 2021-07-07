# frozen_string_literal: true
require "test_helper"

module ThemeCheck
  class DocumentationTest < Minitest::Test
    def setup
      @checks = Check.all
    end

    def test_assert_all_checks_are_documented
      @checks.each do |check_class|
        check = check_class.new
        next if check.code_name == "MockCheck"
        assert(check.doc, "#{check.code_name} should have `doc docs_url(__FILE__)` in the class definition.")
        assert(File.exist?(doc_to_file_path(check.doc)), "#{check.code_name} should be documented in docs/checks/check_class_name.md")
      end
    end

    private

    def doc_to_file_path(doc)
      File.join(
        __dir__,
        '..',
        doc.sub(%r{^https://.+main/}, '')
      )
    end
  end
end
