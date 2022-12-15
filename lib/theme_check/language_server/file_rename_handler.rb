module ThemeCheck
  module LanguageServer
    class FileRenameHandler 
      include URIHelper

      def to_workspace_edit(storage, relative_paths)
        {
          documentChanges: to_text_document_edits(storage, relative_paths)
        }
      end

      private

      def to_text_document_edits(storage, relative_paths)
        snippets = relative_paths
          .map { |(old_path, new_path)| old_path }
          .filter{ |path| path.start_with?("snippets/")  }
          .map{ |path| path.sub(/^snippets\//, '').sub(/.liquid$/, '') }
          
        theme = ThemeCheck::Theme.new(storage)

        # find all files that contain either {% render 'snippetName' %} or {% include 'snippetName' %}
        theme.liquid.map do |liquid_file|
          {
            textDocument: {
              uri: file_uri(liquid_file.path),
              version: storage.version(liquid_file.relative_path)
            },
            edits: to_text_edits(liquid_file, storage, relative_paths)
          }
        end
        #.reject(te => te.edits.empty?)
      end

      def to_text_edits(liquid_file, storage, relative_paths)
        handler = LiquidNodeRenameHandler.new
        visitor = LiquidNodeVisitor.new([handler])
        visitor.visit_liquid_file(liquid_file)
        
        binding.pry
        # have an array of nodes
        # turn this into an array of edits
        # replace old with new, and we wont replace with the full path... should only be part 
        # of the path

        # for nodes 
        # for relative paths, see if need to be replaced and create a text edit
        #filter out empty text edits 
        
        # node_finder = ...
        # visitor = ...
        # visitor.visit
        # const [renderNodes, assetUrlNodes, sectionsNodes] = render_finder
        # ## ... 
        # text_edits = renderNodeTextEdits + assetUrlTextEdits + sectionsTextEdits
        def to_text_edit(node, relative_paths)
          # assume no path to file YET, might have to eventually... and can just replace file name
          # for each relative path, get text edit for node 
          # if no edit just add empty hash
        end
      end
    end
  end
end