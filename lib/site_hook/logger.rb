require 'logging'
require 'active_support/core_ext/string'
Logging.init %w(NONE DEBUG INFO WARN ERROR FATAL)
Logging.color_scheme(
    'bright',
    :levels  => {
        :info  => :blue,
        :warn  => :yellow,
        :error => :red,
        :fatal => [:white, :on_red],
    },
    :date    => :white,
    :logger  => :cyan,
    :message => :green,
    )

layout = Logging.layouts.pattern \
  :pattern      => '[%d] %-5l %c: %m\n',
  :date_pattern => '%Y-%m-%d %H:%M:%S',
  :color_scheme => 'bright'

Logging.appenders.stdout \
  :layout => layout

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

    def initialize(log_level = 'info')
      @log    = Logging.logger[SiteHook.safe_log_name(self)]
      flayout = Logging.appenders.rolling_file \
        Pathname(Dir.home).join('.jph', 'logs', "#{SiteHook.safe_log_name(self)}-#{@log_level}.log").to_s,
        :age     => 'daily',
        :pattern => '[%d] %-5l %c: %m\n'
      @log.add_appenders 'stdout', flayout
      @log.level = log_level
    end
  end

  mklogdir
  LL = LogLogger.new
  LL.log.debug "#{LL.class} initialized."

  class HookLogger
    class HookLog
      attr :log
      attr :log_level

      def initialize(log_level = nil)
        LL.log.debug "Initializing #{SiteHook.safe_log_name(self)}"
        @log    = Logging.logger[SiteHook.safe_log_name(self)]
        flayout = Logging.appenders.rolling_file \
          Pathname(Dir.home).join('.jph', 'logs', "#{SiteHook.safe_log_name(self)}-#{@log_level}.log").to_s,
          :age     => 'daily',
          :pattern => '[%d] %-5l %c: %m\n'
        @log.add_appenders 'stdout', flayout
        @log.level = log_level
        LL.log.debug "Initialized #{SiteHook.safe_log_name(self)}"
      end
    end

    class BuildLog
      attr :log

      def initialize(log_level = nil)
        LL.log.debug "Initializing #{SiteHook.safe_log_name(self)}"
        @log    = Logging.logger[SiteHook.safe_log_name(self)]
        flayout = Logging.appenders.rolling_file \
          Pathname(Dir.home).join('.jph', 'logs', "#{SiteHook.safe_log_name(self)}-#{@log_level}.log").to_s,
          :age     => 'daily',
          :pattern => '[%d] %-5l %c: %m\n'
        @log.add_appenders 'stdout', flayout
        @log.level = log_level
        LL.log.debug "Initialized #{SiteHook.safe_log_name(self)}"
      end
    end

    class GitLog
      attr :log

      def initialize(log_level = nil)
        LL.log.debug "Initializing #{SiteHook.safe_log_name(self)}"
        @log    = Logging.logger[SiteHook.safe_log_name(self)]
        flayout = Logging.appenders.rolling_file \
          Pathname(Dir.home).join('.jph', 'logs', "#{SiteHook.safe_log_name(self)}-#{@log_level}.log").to_s,
          :age     => 'daily',
          :pattern => '[%d] %-5l %c: %m\n'
        @log.add_appenders 'stdout', flayout
        @log.level = log_level
        LL.log.debug "Initialized #{SiteHook.safe_log_name(self)}"
      end
    end
  end
end
