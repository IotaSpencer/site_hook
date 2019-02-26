require 'site_hook/string_ext'
require 'logger'
require 'recursive_open_struct'

module SiteHook
  class Log
    @@levels    = {
        unknown: ::Logger::UNKNOWN,
        fatal:   ::Logger::FATAL,
        error:   ::Logger::ERROR,
        info:    ::Logger::INFO,
        debug:   ::Logger::DEBUG
    }
    def initialize
      log_types       = %w[app hook build git fake]
      logs_with_level = %w[app hook build git]
      @@loggers       = RecursiveOpenStruct.new({access: nil, app: nil, hook: nil, build: nil, fake: nil, git: nil})
      @@loggers.to_h.each do |logclass, value|
        path                = "#{logclass.to_s.camelize}"
        level = ''
        @@loggers[logclass] = SiteHook::Loggers.const_get(path)

        if logs_with_level.include?(logclass.to_s)
          if SiteHook::Config.log_levels.fetch("#{logclass}")
            level = SiteHook::Config.log_levels.instance_variable_get(:"@#{logclass}")
          end
        end
        SiteHook::Log.remove_const(logclass.to_s.camelize) if SiteHook::Log.const_defined?(logclass.to_s.camelize)
        SiteHook::Log.const_set(logclass.to_s.camelize, value.new(logclass.to_s.camelize, "#{level}"))
      end
      @@loggers.to_h.each do |key, value|

      end
     end

    def self.flush
      # Intentionally left blank
    end
  end
  class Logger
    @@levels    = {
        unknown: ::Logger::UNKNOWN,
        fatal:   ::Logger::FATAL,
        error:   ::Logger::ERROR,
        info:    ::Logger::INFO,
        debug:   ::Logger::DEBUG
    }
    def initialize(klass, level)
      @loggers = {
          stdout: ::Logger.new(STDOUT, progname: klass.to_s.camelcase),
          stderr: ::Logger.new(STDERR, progname: klass.to_s.camelcase),
          file:   ::Logger.new(SiteHook::Paths.make_log_name(klass, level), progname: klass.to_s.camelcase)
      }
      @loggers.each do |_logger, obj|
        obj.datetime_format = '%Y-%m-%dT%H:%M:%S%Z'
        obj.formatter = proc do |severity, datetime, progname, msg|
          "#{severity} [#{datetime}] #{progname} —— #{msg}\n"
        end
      end
    end
    def unknown(obj)
      @loggers.each do |key, value|
        value.unknown(obj)
      end
    end
    def error(obj)
      @loggers.each do |key, value|
        value.error(obj)
      end
    end
    def info(obj)
      @loggers.each do |key, value|
        next if key == :stderr
        value.info(obj)
      end
    end
    def fatal(obj)
      @loggers.each do |key, value|
        next if key == :stderr
        value.fatal(obj)
      end
    end
    def warn(obj)
      @loggers.each do |key, value|
        value.warn(obj)
      end
    end
    # @param [Symbol] level log level to log at
    # @param [Object] obj some kind of object or msg to log
    def log(level, obj)
      @loggers.each do |logger|
        logger.add(@@levels[level], obj)
      end
    end

    def log_raw(msg)
      self.<<(msg.dup)

    end
  end

  def flush
    # Intentionally left blank
  end
end
module SiteHook
  module Loggers
    class Access < SiteHook::Logger
    end
    class App < SiteHook::Logger
    end
    class Build < SiteHook::Logger
    end
    class Hook < SiteHook::Logger
    end
    class Git < SiteHook::Logger
    end

    class Fake < StringIO
      attr :info_output, :debug_output

      def initialize(_, _)
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
            info:  @info_output,
            debug: @debug_output
        }
      end
    end
  end
end