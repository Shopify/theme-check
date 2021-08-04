# frozen_string_literal: true

module ThemeCheck
  class Corrector
    def initialize(theme_file:)
      @theme_file = theme_file
    end

    def insert_after(node, content)
      @theme_file.rewriter.insert_after(node, content)
    end

    def insert_before(node, content)
      @theme_file.rewriter.insert_before(node, content)
    end

    def remove(node)
      @theme_file.rewriter.remove(node)
    end

    def replace(node, content)
      @theme_file.rewriter.replace(node, content)
      node.markup = content
    end

    def wrap(node, insert_before, insert_after)
      @theme_file.rewriter.wrap(node, insert_before, insert_after)
    end

    def create(theme, relative_path, content)
      theme.storage.write(relative_path, content)
    end

    def create_default_locale_json(theme)
      theme.default_locale_json = JsonFile.new("locales/#{theme.default_locale}.default.json", theme.storage)
      theme.default_locale_json.update_contents({})
    end

    def remove_file(theme, relative_path)
      theme.storage.remove(relative_path)
    end

    def mkdir(theme, relative_path)
      theme.storage.mkdir(relative_path)
    end

    def add_default_translation_key(file, key, value)
      hash = file.content
      key.reduce(hash) do |pointer, token|
        return pointer[token] = value if token == key.last
        pointer[token] = {} unless pointer.key?(token)
        pointer[token]
      end
      file.update_contents(hash)
    end
  end
end
