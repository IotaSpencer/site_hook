require 'logging'

module SiteHook
  def mklogdir
    path = Pathname(Dir.home).join('.jph', 'logs')
    if path.exist?
    else
      FileUtils.mkpath(path.to_s)
    end
  end

  module_function :mklogdir

  class LogLogger
    attr :log
    attr :log_level

    def initialize(log_level = nil)
      @log = Logging.logger[self.class.to_s]
      @log.level = log_level
      Logging.appenders.rolling_file(
        Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
        :age => 'daily',
        :layout => Logging.layouts.pattern(color_scheme: 'default'),
      )
    end
  end

  mklogdir
  @@ll = LogLogger.new
  @@ll.log.debug "#{@@ll.class} initialized."

  class HookLogger
    Logging.logger.root.appenders = Logging.appenders.stdout

    class Hook
      attr :log
      attr :log_level

      def initialize(log_level = nil)
        @@ll.log.debug "Initializing #{self}"
        @log = Logging.logger[self.class.to_s]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
          :layout => Logging.layouts.pattern(color_scheme: 'default'),
        )
        @@ll.log.debug "Initialized #{self}"
      end
    end

    class Build
      attr :log

      def initialize(log_level = nil)
        @@ll.log.debug "Initializing #{self}"
        @log = Logging.logger[self.class.to_s]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
          :layout => Logging.layouts.pattern(color_scheme: 'default'),
        )
        @ll.log.debug "Initialized #{self}"
      end
    end
  end
end
