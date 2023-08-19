# frozen_string_literal: true
require "test_helper"

module PlatformosCheck
  module LanguageServer
    class IOMessengerTest < Minitest::Test
      def setup
        @in = StringIO.new
        @out = StringIO.new
        @err = StringIO.new
        @messenger = IOMessenger.new(
          in_stream: @in,
          out_stream: @out,
          err_stream: @err
        )
      end

      def test_read_message_with_content_length_header
        messages = ["hi", "muffin"]
        messages.each do |message|
          @in.puts "Content-Length: #{message.bytesize}\r\n\r\n#{message}"
        end
        @in.rewind

        t = Thread.new do
          messages.map { @messenger.read_message }
        end

        assert_equal(messages, t.join.value)
      end

      def test_read_message_skips_lines_without_content_length_header
        message = "hello"
        @in.puts "Potatoes are the king of the garden\n"
        @in.puts "Content-Length: #{message.bytesize}\r\n\r\n#{message}"
        @in.rewind

        t = Thread.new do
          @messenger.read_message
        end

        assert_equal(message, t.join.value)
      end

      def test_read_message_throws_done_streaming_when_done_reading_cleanly
        message = "hello"
        @in.puts "Content-Length: #{message.bytesize}\r\n\r\n#{message}"
        @in.rewind

        assert_raises(DoneStreaming) do
          @messenger.read_message
          @messenger.read_message
        end
      end

      def test_read_message_throws_done_streaming_when_done_reading_dirty
        message = "hello"
        @in.puts "Content-Length: #{message.bytesize}\r\n\r\nhe"
        @in.rewind

        assert_raises(DoneStreaming) do
          @messenger.read_message
          @messenger.read_message
        end
      end

      def test_send_message_with_content_length_header
        message = "hi muffin"
        @messenger.send_message(message)
        @out.rewind
        assert_equal("Content-Length: #{message.size}\r\n\r\n#{message}", @out.string)
      end
    end
  end
end
