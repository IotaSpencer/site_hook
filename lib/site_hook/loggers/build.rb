module SiteHook
  module Loggers
    class Build
      def initialize(base:, level:)
        @@levels  = {
            unknown: ::Logger::UNKNOWN,
            fatal:   ::Logger::FATAL,
            error:   ::Logger::ERROR,
            info:    ::Logger::INFO,
            debug:   ::Logger::DEBUG
        }
        @@loggers = {
            stdout: ::Logger.new(STDOUT, progname: base),
            stderr: ::Logger.new(STDERR, progname: base),
            file:   ::Logger.new(SiteHook::Paths.make_log_name(base, level), progname: base)
        }
        @@loggers.each do |_logger, obj|
          obj.datetime_format = '%Y-%m-%dT%H:%M:%S%Z'
          obj.formatter       = proc do |severity, datetime, progname, msg|
            "#{severity} [#{datetime}] #{progname} —— #{msg}\n"
          end
        end
      end

      def unknown(obj)
        @@loggers.each do |_key, value|
          value.unknown(obj)
        end
      end

      def error(obj)
        @@loggers.each do |_key, value|
          value.error(obj)
        end
      end

      def info(obj)
        @@loggers.each do |key, value|
          next if key == :stderr
          value.info(obj)
        end
      end

      def fatal(obj)
        @@loggers.each do |key, value|
          next if key == :stderr
          value.fatal(obj)
        end
      end

      def warn(obj)
        @@loggers.each do |_key, value|
          value.warn(obj)
        end
      end
      def debug(obj)
        @@loggers.each do |_key, value|
          value.debug(obj)
        end
      end

      # @param [Symbol] level log level to log at
      # @param [Object] obj some kind of object or msg to log
      def log(level, obj)
        @@loggers.each do |logger|
          logger.add(@levels[level], obj)
        end
      end

      def log_raw(msg)
        @@loggers.each do |logger|
          logger.<<(obj)
        end
      end
    end
  end
end