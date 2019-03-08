module SiteHook
  module Loggers
    class Access
      def initialize(base: 'ACCESS')
        @@loggers = {
            stdout: ::Logger.new(STDOUT, progname: base),
            file: ::Logger.new(SiteHook::Paths.make_log_name(base), progname: base)
        }
      end
      # @param [Symbol] level log level to log at
      # @param [Object] obj some kind of object or msg to log
      def log(obj)
        @@loggers.each do |_type, logger|

          logger.<< "[#{Time.now}] #{obj}\n"
        end
      end
    end
  end
end
