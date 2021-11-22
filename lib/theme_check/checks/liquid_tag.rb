# frozen_string_literal: true
module ThemeCheck
  # Recommends using {% liquid ... %} if 5 or more consecutive {% ... %} are found.
  class LiquidTag < LiquidCheck
    severity :suggestion
    category :liquid
    doc docs_url(__FILE__)

    def initialize(min_consecutive_statements: 5)
      # @first_statement = nil
      @first_nodes = []
      @first_statement = nil
      @consecutive_statements = 0
      @min_consecutive_statements = min_consecutive_statements
      @consecutive_nodes = {}
      #(first statement) line_number -> conseuctive nodes []
    end

    def on_tag(node)
      if node.inside_liquid_tag?
        reset_consecutive_statements
      # Ignore comments
      elsif !node.comment?
        "first statement nil? 0: #{@first_statement.nil?}"
        increment_consecutive_statements(node)
      end
      #if 
    end

    def on_string(node)
      # Only reset the counter on outputted strings, and ignore empty line-breaks
      if node.parent.block? && !node.value.strip.empty?
        puts "STRING RESET"
        pp @consecutive_statements
        reset_values
      end
    end

    def after_document(_node)
      # We do all the corrections for a document here at the end of each file
      # Array of first_nodes that we iterate through and use to access the hash with the consecutive nodes
      # Value reset is separate from correction so it occurs in a timely manner
      puts "EOF RESET"
      pp @consecutive_statements
      reset_values
      puts "length: #{@first_nodes.length}"
      # check if multiple corrections is true/false
      
      first = true
      lines_removed = 0
      @first_nodes.each do |node|
        add_offense("Use {% liquid ... %} to write multiple tags", node: node) do |corrector|
          puts "STARTING CORRECTION"
          lines = node.source.split("\n").collect(&:rstrip)
          # remove tags to be replaced by liquid tag
          # TODO: All on one line
          @consecutive_nodes[node.line_number][1..-1].each do |n|
            corrector.remove_liquid_tag(n)
            if n.markup == "assign c = 3\n"
              binding.pry
            end
          end
          # construct liquid tag with consecutive nodes (remove opening/closing tags + add liquid to opening tag)
          consecutive = " #{lines[node.line_number - 1, @consecutive_nodes[node.line_number][-1].line_number].join("\n ")}\n".gsub(/{%-| -%}|{%| %}/, "")
          # binding.pry
          corrector.replace(node, "liquid\n#{consecutive}")
          puts "CORRECTION COMPLETE"
          # binding.pry
          # call delete from inside here 
        end
        # PROBLEM: finding the start_index and replacing the old node, line_number is obsolete
        # don't use replace, use insert instead? we need the index at which to insert
        # we have the line_number
        # create a new position with the right line number
        # replace and then remove after (has to be within corrector block though)
      end
      # start_line_offset is off because of removal of lines
      # line number updates are not happening  
      # update line_number on node
      # removals affect line numbers - remove at the end possibly so removals don't affect line numbers
      # keep track of lines removed and offset the indices by that number
      @first_nodes = []
    end

    def remove
      
      
    end

    def increment_consecutive_statements(node)
      # if @bol == true
      #   @first_nodes << node 
      #   @first_statement = false
      # end
      @first_statement ||= node
      puts "INCREMENT"
      puts "first_statement line no. #{@first_statement.line_number}"
      @consecutive_statements += 1
      if !@consecutive_nodes[@first_statement.line_number]
        @consecutive_nodes[@first_statement.line_number] = []
      end
      @consecutive_nodes[@first_statement.line_number] << node
      # This doesn't seem to change regardless of what I put as the key
      puts "num consecutive nodes #{@consecutive_nodes[@first_statement.line_number].length}"
      puts @consecutive_nodes.keys
    end

    # def reset_consecutive_statements
    #   if (@consecutive_statements >= @min_consecutive_statements)
    #     puts "type? #{@first_statement.type_name}"
    #     add_offense("Use {% liquid ... %} to write multiple tags", node: @first_statement) do |corrector|
    #       puts "length? #{@const}"
    #       puts "nil? #{@first_statement.nil?}"
    #       # how do we correct multiple things without losing @first_statement
    #       # values are not reset until the very end of file -> doesn't make sense
    #       next if @first_statement.nil?
    #       lines = @first_statement.source.split("\n").collect(&:rstrip)
    #       # remove tags to be replaced by liquid tag
    #       @first_statement.source.sub!("\n#{lines[@first_statement.line_number, @consecutive_nodes[@first_statement.line_number][-1].line_number + 1].join("\n")}", "")
    #       # construct liquid tag with consecutive nodes (remove opening/closing tags + add liquid to opening tag)
          
    #       consecutive = " #{lines[@first_statement.line_number - 1, @consecutive_nodes[@first_statement.line_number][-1].line_number + 1].join("\n ")}\n".gsub(/{%-| -%}|{%| %}/, "")
    #       corrector.replace(@first_statement, "liquid\n#{consecutive}")
    #       # reset_values
    #       puts "RESET COMPLETE"
    #       # next if @first_statement.nil?
    #       # lines = @first_statement.source.split("\n").collect(&:rstrip)
    #       # # remove tags to be replaced by liquid tag
    #       # @first_statement.source.sub!("\n#{lines[@consecutive_nodes[1].line_number - 1, @consecutive_nodes[-1].line_number].join("\n")}", "")
    #       # # construct liquid tag with consecutive nodes (remove opening/closing tags + add liquid to opening tag)
    #       # consecutive = " #{lines[@first_statement.line_number - 1, @consecutive_nodes[-1].line_number + 1].join("\n ")}\n".gsub(/{%-| -%}|{%| %}/, "")
    #       # corrector.replace(@first_statement, "liquid\n#{consecutive}")
    #       # reset_values
    #     end
    #   else
    #     reset_values
    #   end
    # end

    def reset_values
      if (@consecutive_statements >= @min_consecutive_statements)
        puts "GOLDENNNNNN"
        @first_nodes << @first_statement
      end
      @first_statement = nil
      @consecutive_statements = 0
      puts "first statement should now be nil: #{@first_statement.nil?} #{@consecutive_statements}"
    end
  end
end
