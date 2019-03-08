require 'site_hook/string_ext'
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
        raise ArgumentError "invalid log type in config"
      end
    end
    def inspect
      meths    = %i[hook build git app]
      sections = {}
      meths.each do |m|
        sections[m] = self.class.send(m).inspect
      end
      secs = []
      sections.each { |name, instance| secs << "#{name}=#{instance}" }
      "#<SiteHook::Log #{secs.join(' ')}>"
    end

    def self.reload!
      @@config = YAML.load_file(@@filename)
    end

    def self.filename
      @@filename
    end

    def self.config
      self.new
    end

    def initialize
      @@config          = {}
      @@config_filename = SiteHook::Paths.default_config
      begin
        @@config = YAML.load_file(@@config_filename)
        validate(@@config)
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
      Access.new(level: nil, base: self)
    end
    def self.fake
      Fake.new(level: nil)
    end
    # @return [Hook]
    def self.hook
      Hook.new(level: @@config['log_levels']['hook'])
    end

    # @return [Git]
    def self.git
      Git.new(level: @@config['log_levels']['git'])
    end

    # @return [Build]
    def self.build
      Build.new(level: @@config['log_levels']['build'], base: self)
    end

    # @return [LogLevels]
    def self.app
      App.new(level: @@config['log_levels']['app'])
    end
  end
  module Logger
    def initialize(level:, base:)
      @@loggers = {
          stdout: ::Logger.new(STDOUT, progname: base),
          stderr: ::Logger.new(STDERR, progname: base),
          file: ::Logger.new(SiteHook::Paths.make_log_name(base), progname: base)
      }
    end
  end
  class Hook
    include Logger
    def initialize(*args)
      super
    end
    def inspect
      "#<SiteHook::Webhook >"
    end

  end
  class Git
    include Logger

    def initialize(*args)
      super
    end

    def inspect
      "#<SiteHook::Log::Git >"
    end
  end
  class Build
    include Logger
    def initialize(level:, base:)
      super
    end
    def inspect
      "#<SiteHook::Log::Build >"
    end
  end
  class Access
    include Logger
    def initialize(level:, base:)
      super
    end

    def inspect
      "#<SiteHook::Log::Access >"
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