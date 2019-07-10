# 
# Copyright 2019 Ken Spencer / IotaSpencer <me@iotaspencer.me>
# 
# File: /lib/site_hook/prelogger.rb
# Created: 3/9/19
#
# License is in project root, MIT License is in use.

require 'site_hook/paths'
module SiteHook
  class PreLogger
    def initialize(input, output, errput)
      self.class.set_base_default
      @@levels  = {
          unknown: ::Logger::UNKNOWN,
          fatal:   ::Logger::FATAL,
          error:   ::Logger::ERROR,
          info:    ::Logger::INFO,
          debug:   ::Logger::DEBUG
      }
      @@loggers = {
          stdout: ::Logger.new(STDOUT, progname: @@base),
          stderr: ::Logger.new(STDERR, progname: @@base),
          file:   ::Logger.new(SiteHook::Paths.make_log_name(self.to_s), progname: @@base)
      }
      @@loggers.each do |_logger, obj|
        obj.datetime_format = '%Y-%m-%dT%H:%M:%S%Z'
        obj.formatter       = proc do |severity, datetime, progname, msg|
          "#{severity} [#{datetime}] #{progname} —— #{msg}\n"
        end
      end
    end
    def self.base=(base)
      @@base = base.to_s
    end
    def self.set_base_default
      @@base = 'Logger'
    end
    def self.unknown(obj)
      @@loggers.each do |_key, value|
        value.unknown(obj)
      end
    end

    def self.error(obj)
      @@loggers.each do |_key, value|
        value.error(obj)
      end
    end

    def self.info(obj)
      @@loggers.each do |key, value|
        next if key == :stderr
        value.info(obj)
      end
    end

    def self.debug(obj)
      @@loggers.each do |_key, value|
        value.debug(obj)
      end
    end
    def self.fatal(obj)
      @@loggers.each do |key, value|
        next if key == :stderr
        value.fatal(obj)
      end
    end



    # @param [Symbol] level log level to log at
    # @param [Object] obj some kind of object or msg to log
    def self.log(level, obj)
      @@loggers.each do |logger|
        logger.add(@levels[level], obj)
      end
    end

    def self.<<(msg)
      @@loggers.each do |logger|
        logger.<<(msg)
      end

    end

  end
end