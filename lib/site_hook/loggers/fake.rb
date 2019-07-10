module SiteHook
  module Loggers
    class Fake < StringIO
      attr :info_output, :debug_output

      def initialize
        @info_output  = []
        @debug_output = []
      end

      # @param [Any] message message to log
      def info(message)
        case
        when message =~ /git .* pull/
          @info_output << "Starting Git"
          @debug_output << message
        else
          @debug_output << message
        end
      end

      # @param [Any] message message to log
      def debug(message)
        case
        when message =~ /\n/
          msgs = message.lines
          msgs.each do |msg|
            msg.squish!
            case
            when msg =~ /From (.*?):(.*?)\/(.*)(\.git)?/
              @info_output << "Pulling via #{$2}/#{$3} on #{$1}."
            when msg =~ /\* branch (.*?) -> .*/
              @info_output << "Using #{$1} branch"
            else
              @debug_output << msg
            end
          end
        else
          @debug_output << message
        end
      end

      # @return [Hash] Hash of log entries
      def entries
        {
            info: @info_output,
            debug: @debug_output
        }
      end
    end
  end
end