require 'paint'
module SiteHook
  class SiteHookError < StandardError
    def initialize(msg, err)
      super(msg)
      exit err
    end
  end
  class ConfigExistsError < SiteHookError
  end
  class NoConfigError < SiteHookError
    attr_reader :path
    def initialize(path)
      @str = "Config path '#{Paint[path, 'red']}' does not exist!"
      @path = path
      super(@str,98)
    end
  end
  class NeitherConfigError < SiteHookError
    attr_reader :paths
    def initialize
      @str = "Neither '#{SiteHook::Paths.old_config}' nor '#{SiteHook::Paths.config}'"
    end
  end
  class NoLogsError < SiteHookError
    attr_reader :path
    def initialize(path)
      @str = "Log path '#{Paint[path, 'red']}' does not exist!"
      @path = path
      super(@str,97)
    end
  end
end
