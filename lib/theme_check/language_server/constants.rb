# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    PARTIAL_RENDER = %r{
      \{\%-?\s*render\s+'(?<partial>[^']*)'|
      \{\%-?\s*render\s+"(?<partial>[^"]*)"|

      # in liquid tags the whole line is white space until render
      ^\s*render\s+'(?<partial>[^']*)'|
      ^\s*render\s+"(?<partial>[^"]*)"
    }mix
    ASSET_INCLUDE = %r{
      \{\%-?\s*'(?<partial>[^']*)'\s*\|\s*asset_url|
      \{\%-?\s*"(?<partial>[^"]*)"\s*\|\s*asset_url|

      # in liquid tags the whole line is white space until the asset partial
      ^\s*'(?<partial>[^']*)'\s*\|\s*asset_url|
      ^\s*"(?<partial>[^"]*)"\s*\|\s*asset_url
    }mix
  end
end
