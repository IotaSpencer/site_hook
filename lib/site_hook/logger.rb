require 'logging'
require 'active_support/core_ext/string'

module SiteHook
  def mklogdir
    path = Pathname(Dir.home).join('.jph', 'logs')
    if path.exist?
    else
      FileUtils.mkpath(path.to_s)
    end
  end

  def safe_log_name(klass)
    klass.class.name.split('::').last.underscore
  end

  module_function :mklogdir, :safe_log_name

  class LogLogger
    attr :log
    attr :log_level

    def initialize(log_level = nil)
      @log = Logging.logger[SiteHook.safe_log_name(self)]
      @log.level = log_level
      Logging.appenders.rolling_file(
        Pathname(Dir.home).join('.jph', 'logs', "#{self.class.name.split('::').last.underscore}-#{@log.level}.log").to_path,
        :age => 'daily',
      )
    end
  end

  mklogdir
  LL = LogLogger.new
  LL.log.debug "#{LL.class} initialized."

  class HookLogger
    Logging.logger.root.appenders = Logging.appenders.stdout

    class HookLog
      attr :log
      attr :log_level

      def initialize(log_level = nil)
        LL.log.debug "Initializing #{SiteHook.safe_log_name(self)}"
        @log = Logging.logger[SiteHook.safe_log_name(self)]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
        )
        LL.log.debug "Initialized #{SiteHook.safe_log_name(self)}"
      end
    end

    class BuildLog
      attr :log

      def initialize(log_level = nil)
        LL.log.debug "Initializing #{SiteHook.safe_log_name(self)}"
        @log = Logging.logger[SiteHook.safe_log_name(self)]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
        )
        LL.log.debug "Initialized #{SiteHook.safe_log_name(self)}"
      end
    end
  end
end
