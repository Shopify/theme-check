# frozen_string_literal: true

module ThemeCheck
  class Corrector
    def initialize(template:)
      @template = template
    end

    def insert_after(node, content)
      line = @template.full_line(node.line_number)
      line.insert(node.range[1] + 1, content)
    end

    def insert_before(node, content)
      line = @template.full_line(node.line_number)
      line.insert(node.range[0], content)
    end

    def replace(node, content)
      line = @template.full_line(node.line_number)
      line[node.range[0]..node.range[1]] = content
      node.markup = content
    end

    def wrap(node, insert_before, insert_after)
      line = @template.full_line(node.line_number)
      line.insert(node.range[0], insert_before)
      line.insert(node.range[1] + 1 + insert_before.length, insert_after)
    end

    def create(theme, relative_path, content)
      theme.storage.write(relative_path, content)
    end

    def create_default_locale_json(theme)
      theme.default_locale_json = JsonFile.new("locales/#{theme.default_locale}.default.json", theme.storage)
      theme.default_locale_json.update_contents('{}')
    end

    def remove(theme, relative_path)
      theme.storage.remove(relative_path)
    end
  end
end
