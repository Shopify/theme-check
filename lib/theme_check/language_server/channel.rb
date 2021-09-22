# frozen_string_literal: true

module ThemeCheck
  module LanguageServer
    # How you'd use this class:
    #
    # In thread #1:
    #   def foo
    #     chan = Channel.create
    #     send_request(chan.id, ...)
    #     result = chan.pop
    #     do_stuff_with_result(result)
    #   ensure
    #     chan.close
    #   end
    #
    # In thread #2:
    #   Channel.by_id(id) << result
    class Channel
      MUTEX = Mutex.new
      CHANNELS = {}

      class << self
        def create
          id = new_id
          CHANNELS[id] = new(id)
          CHANNELS[id]
        end

        def by_id(id)
          CHANNELS[id]
        end

        def close(id)
          CHANNELS.delete(id)
        end

        private

        def new_id
          MUTEX.synchronize do
            @id ||= 0
            @id += 1
          end
        end
      end

      attr_reader :id

      def initialize(id)
        @id = id
        @response = SizedQueue.new(1)
      end

      def pop
        @response.pop
      end

      def <<(value)
        @response << value
      end

      def close
        @response.close
        Channel.close(id)
      end
    end
  end
end
