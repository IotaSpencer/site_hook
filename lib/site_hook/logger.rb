require 'logger'
require 'recursive_open_struct'
require 'site_hook/loggers'
require 'site_hook/paths'
require 'yaml'
require 'site_hook/string_ext'
#require 'site_hook/configs'
module SiteHook
  class Log
    def self.defaults
      RecursiveOpenStruct.new(
          {
              Hook:   {
                  level: 'info'
              },
              App:    {
                  level: 'info'
              },
              Build:  {
                  level: 'info'
              },
              Git:    {
                  level: 'info'
              },
              Access: {
                  level: nil
              },
              Fake:   {
                  level: nil
              }
          })
    end

    def self.validate(config)
      invalid_types = []
      valid_config_log_types = [
          'hook',
          'git',
          'app',
          'build'
      ]
      invalid_config_log_types = [
          'access',
          'fake'
      ]
      config = config['log_levels']
      is_config_valid = config.all? do |x|
        if valid_config_log_types.include? x
          true
        else
          if invalid_config_log_types.include? x
            invalid_types << x
            false
          end
        end
      end
      unless is_config_valid
        raise ArgumentError "invalid log type(s) in config, [#{invalid_types.join(', ')}]"
      end
    end
    def inspect
      meths    = %i[hook build git app fake access]
      sections = {}
      meths.each do |m|
        sections[m] = self.class.send(m).inspect
      end
      secs = []
      sections.each { |name, instance| secs << "#{name}=#{instance}" }
      "#<SiteHook::Log #{secs.join(' ')}>"
    end

    def initialize
      @@config          = SiteHook::Config.log_levels
      @@config_filename = SiteHook::Paths.default_config
      begin
        self.validate(@@config)
      rescue Errno::ENOENT
        raise NoConfigError path
      rescue NoMethodError
        if @@config_filename.empty?
          raise "Config is Empty!!!"
        end
      end
    end

    # @return [Access]
    def self.access
      Loggers::Access.new(base: 'SiteHook::Log::Access')
    end
    def self.fake
      Loggers::Fake.new
    end
    # @return [Hook]
    def self.hook
      Loggers::Hook.new(level: @@config['log_levels']['hook'], base: 'SiteHook::Log::Hook')
    end

    # @return [Git]
    def self.git
      Loggers::Git.new(level: @@config['log_levels']['git'], base: 'SiteHook::Log::Git')
    end

    # @return [Build]
    def self.build
      Loggers::Build.new(level: @@config['log_levels']['build'], base: 'SiteHook::Log::Build')
    end

    # @return [LogLevels]
    def self.app
      Loggers::App.new(level: @@config['log_levels']['app'], base: 'SiteHook::Log::App')
    end
  end
end
# module SiteHook
#   class Log
#     def initialize
#       @loggers = {
#           Access: {_class: SiteHook::Loggers::Access, has_level: false},
#           App:    {_class: SiteHook::Loggers::App, has_level: true},
#           Hook:   {_class: SiteHook::Loggers::Hook, has_level: true},
#           Build:  {_class: SiteHook::Loggers::Build, has_level: true},
#           Git:    {_class: SiteHook::Loggers::Git, has_level: true},
#           Fake:   {_class: SiteHook::Loggers::Fake, has_level: false}
#       }
#       @loggers.each do |logclass, value|
#         _class    = value.to_h.fetch(:_class)
#         has_level = value.to_h.fetch(:has_level)
#         level     = ''
#         if has_level
#           if SiteHook::Config.log_levels.fetch("#{logclass.to_s.downcase}")
#             level = SiteHook::Config.log_levels.instance_variable_get(:"@#{logclass.to_s.downcase}")
#             level = "-#{level}"
#             self.class.remove_const(logclass) if SiteHook::Log.const_defined?(logclass)
#             self.class.const_set(logclass, _class.new(logclass, level))
#           end
#         else
#           self.class.remove_const(logclass) if SiteHook::Log.const_defined?(logclass)
#           case logclass
#           when :Access
#             self.class.const_set(logclass, _class.new(logclass))
#           when :Fake
#             self.class.const_set(logclass, _class.new)
#           end
#
#         end
#
#
#       end
#     end
#
#     def self.flush
#       # Intentionally left blank
#     end
#   end
#
#
#   def flush
#     # Intentionally left blank
#   end
# end