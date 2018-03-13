require 'logging'

module SiteHook
  class LogLogger
    attr :log
    attr :log_level

    def initialize(log_level = nil)
      @log = Logging.logger[self.class.to_s]
      @log.level = log_level
      Logging.appenders.rolling_file(
        Pathname(Dir.home).join('.jph', 'logs', "#{self.class.gsub(/::/, '').to_s.downcase}-#{@log.level}.log").to_path,
        :age => 'daily',
        :layout => Logging.layouts.pattern(color_scheme: 'default'),
      )
    end
  end
  @@ll = LogLogger.new
  @@ll.debug "#{@@ll.class} initialized."
  class HookLogger
    Logging.logger.root.appenders = Logging.appenders.stdout

    def HookLogger.mklogdir
      
      path = Pathname(Dir.home).join('.jph', 'logs')
      @@ll.debug("Checking if #{path} exists.")
      if path.exist?
        @@ll.debug("#{path} exists. Continuing as normal.")
      else
        @@ll.debug("#{path} doesn't exist. Creating.. ")
        FileUtils.mkpath(path.to_s)
        @@ll.debug("#{path} created.")
      end
    end

    class Hook
      attr :log
      attr :log_level
      
      def initialize(log_level = nil)
        @@ll.debug "Initializing #{self}"
        @log = Logging.logger[self.class.to_s]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
          :layout => Logging.layouts.pattern(color_scheme: 'default'),
        )
        @@ll.debug "Initialized #{self}"
      end
    end

    class Build
      attr :log

      def initialize(log_level = nil)
        @@ll.debug "Initializing #{self}"
        @log = Logging.logger[self.class.to_s]
        @log.level = log_level
        Logging.appenders.rolling_file(
          Pathname(Dir.home).join('.jph', 'logs', "#{self.class.to_s.gsub(/::/, '').downcase}-#{@log.level}.log").to_path,
          :age => 'daily',
          :layout => Logging.layouts.pattern(color_scheme: 'default'),
        )
        @ll.debug "Initialized #{self}"
      end
    end
  end
end
