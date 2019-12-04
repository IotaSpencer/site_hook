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
      invalid_types            = []
      valid_config_log_types   = [
          'hook',
          'git',
          'app',
          'build'
      ]
      invalid_config_log_types = [
          'access',
          'fake'
      ]
      config                   = config['log_levels']
      is_config_valid          = config.all? do |x|
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

    def initialize(input, output, errput)

      begin
        @@config = SiteHook::Config.log_levels
      rescue Errno::ENOENT
        raise NoConfigError path
      rescue NoMethodError

      end

    end

    # @return [Access]
    def self.access
      Loggers::Access.new(base: 'SiteHook::Log::Access')
    end

    # @return [Loggers::Fake]
    def self.fake
      Loggers::Fake.new
    end

    # @return [Loggers::Hook]
    def self.hook
      Loggers::Hook.new(level: @@config.hook, base: 'SiteHook::Log::Hook')
    end

    # @return [Loggers::Git]
    def self.git
      Loggers::Git.new(level: @@config.git, base: 'SiteHook::Log::Git')
    end

    # @return [Loggers::Build]
    def self.build
      Loggers::Build.new(level: @@config.build, base: 'SiteHook::Log::Build')
    end

    # @return [Loggers::App]
    def self.app
      Loggers::App.new(level: @@config.app, base: 'SiteHook::Log::App')
    end
  end
end