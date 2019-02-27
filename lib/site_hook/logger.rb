require 'site_hook/string_ext'
require 'logger'
require 'recursive_open_struct'
require 'site_hook/loggers'
module SiteHook
  class Log
    def initialize
      @loggers = {
        Access: {_class: SiteHook::Loggers::Access, has_level: false},
        App: {_class: SiteHook::Loggers::App, has_level: true},
        Hook: {_class: SiteHook::Loggers::Hook, has_level: true},
        Build: {_class: SiteHook::Loggers::Build, has_level: true},
        Git: {_class: SiteHook::Loggers::Git, has_level: true},
        Fake: {_class: SiteHook::Loggers::Fake, has_level: false}
      }
      @loggers.each do |logclass, value|
        _class             = value.to_h.fetch(:_class)
        has_level          = value.to_h.fetch(:has_level)
        level              = ''
        if has_level
          if SiteHook::Config.log_levels.fetch("#{logclass.to_s.downcase}")
            level = SiteHook::Config.log_levels.instance_variable_get(:"@#{logclass.to_s.downcase}")
            level = "-#{level}"
            self.class.remove_const(logclass) if SiteHook::Log.const_defined?(logclass)
            self.class.const_set(logclass, _class.new(logclass, level))
          end
        else
          self.class.remove_const(logclass) if SiteHook::Log.const_defined?(logclass)
          case logclass
          when :Access
            self.class.const_set(logclass, _class.new(logclass))
          when :Fake
            self.class.const_set(logclass, _class.new)
          end

        end


      end
    end

    def self.flush
      # Intentionally left blank
    end
  end


  def flush
    # Intentionally left blank
  end
end