# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    def self.partial_tag(tag)
      %r{
        \{\%-?\s*#{tag}\s+'(?<partial>[^']*)'|
        \{\%-?\s*#{tag}\s+"(?<partial>[^"]*)"|

        # in liquid tags the whole line is white space until the tag
        ^\s*#{tag}\s+'(?<partial>[^']*)'|
        ^\s*#{tag}\s+"(?<partial>[^"]*)"
      }mix
    end

    PARTIAL_RENDER = partial_tag('render')
    PARTIAL_INCLUDE = partial_tag('include')
    PARTIAL_SECTION = partial_tag('section')

    ASSET_INCLUDE = %r{
      \{\{-?\s*'(?<partial>[^']*)'\s*\|\s*asset_url|
      \{\{-?\s*"(?<partial>[^"]*)"\s*\|\s*asset_url|

      # in liquid tags the whole line is white space until the asset partial
      ^\s*(?:echo|assign[^=]*\=)\s*'(?<partial>[^']*)'\s*\|\s*asset_url|
      ^\s*(?:echo|assign[^=]*\=)\s*"(?<partial>[^"]*)"\s*\|\s*asset_url
    }mix
  end
end
