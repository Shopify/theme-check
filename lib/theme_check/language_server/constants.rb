# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    def self.partial_tag(tag, prefix: '')
      %r{
        \{\%-?\s*#{tag}\s+'#{prefix}(?<partial>[^/']+)'|
        \{\%-?\s*#{tag}\s+"#{prefix}(?<partial>[^/"]+)"|

        # in liquid tags the whole line is white space until the tag
        ^\s*#{tag}\s+'#{prefix}(?<partial>[^/']+)'|
        ^\s*#{tag}\s+"#{prefix}(?<partial>[^/"]+)"
      }mix
    end

    def self.partial_pipe(pipe)
      %r{
        \{\{-?\s*'(?<partial>[^']+)'\s*\|\s*#{pipe}|
        \{\{-?\s*"(?<partial>[^"]+)"\s*\|\s*#{pipe}|

        # in liquid tags the whole line is white space until the asset partial
        ^\s*(?:echo|assign[^=]*\=)\s*'(?<partial>[^']+)'\s*\|\s*#{pipe}|
        ^\s*(?:echo|assign[^=]*\=)\s*"(?<partial>[^"]+)"\s*\|\s*#{pipe}
      }mix
    end

    PARTIAL_RENDER = partial_tag('render')
    PARTIAL_INCLUDE = partial_tag('include')
    COMPONENT_RENDER = partial_tag('render', prefix: 'components/')
    COMPONENT_INCLUDE = partial_tag('include', prefix: 'components/')
    ASSET_INCLUDE = partial_pipe('asset')
  end
end
