require 'site_hook/paths'
require 'yaml'
require 'site_hook/string_ext'
#require 'site_hook/configs'
module SiteHook
  class Config
    def self.defaults
      RecursiveOpenStruct.new({
          webhook: {
              host: '127.0.0.1',
              port: 9090
          },
          cli: {
              config: {
                  mkpass: {
                      length: 20,
                      symbols: 0
                  }
              }
          },
          log_levels: {
              app: 'info',
              hook: 'info',
              build: 'info',
              git: 'info'
          },
          projects: {

          }
      })
    end
    def self.validate(config)
      config.each do |section, hsh|
        case section.to_s
        when 'webhook'
          if hsh['port']
          else

          end
        when 'log_levels'
        when 'cli'
        when 'projects'
        else
          raise UnknownFieldError section
        end
      end
    end
    def inspect
      meths = %i[webhook log_levels cli projects]
      sections = {}
      meths.each do |m|
        sections[m] = self.class.send(m).inspect
      end
      secs = []
      sections.each{ |name, instance| secs << "#{name}=#{instance}"}
      "#<SiteHook::Config #{secs.join(' ')}>"
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
      @@config   = {}
      @@filename = SiteHook::Paths.default_config
      begin
        @@config = YAML.load_file(@@filename)
        validate(@@config)
      rescue Errno::ENOENT
        raise NoConfigError path
      rescue NoMethodError
        @@filename.empty?
      end
    end

    # @return [Webhook]
    def self.webhook
      Webhook.new(@@config['webhook'])
    end

    # @return [Projects]
    def self.projects
      Projects.new(@@config['projects'])
    end

    # @return [Cli]
    def self.cli
      Cli.new(@@config['cli'])
    end

    # @return [LogLevels]
    def self.log_levels
      LogLevels.new(@@config['log_levels'])
    end
  end
  module Section
    def initialize(config)
      # nothing right now
    end
  end
  class Webhook
    include Section

    def initialize(config)
      # super
      config.each do |option, value|
        sec = StrExt.mkatvar(option)
        self.instance_variable_set(:"#{sec}", value)
      end
    end
    def host
      @host
    end
    def port
      @port
    end
    def inspect
      "#<SiteHook::Webhook host=#{host} port=#{port}>"
    end

  end
  class Projects
    include Section

    def initialize(config)
      # super
      @projects = []
      config.each do |project, options|
        @projects << Project.new(StrExt.mkvar(project), options)
        self.define_method(:"#{StrExt.mkvar(project)}") do
          Project.new(StrExt.mkvar(project), options)
        end
      end
    end
    def inspect
      project_list = []
      @projects.each do |project|
        project_list << "#{project.name}=#{project.inspect}"
      end
      "#<SiteHook::Projects #{project_list.join(' ')}>"
    end
  end
  class LogLevels
    include Section
    attr :app, :hook, :build, :git
    def initialize(config)
      # super
      defaults = LogLevels.defaults
      defaults.each do |type, level|
        instance_variable_set(:"@#{type}", level)
        begin
        if config.fetch(type, nil)
          level type, level
        end
        rescue
        end
      end
    end
    def inspect
      levels = []
      instance_variables.each do |var|
        levels << "#{StrExt.rematvar(var)}=#{self.instance_variable_get(var)}"
      end
      "#<SiteHook::LogLevels #{levels.join(' ')}>"
    end
    def fetch(key)
      instance_variable_get(:"@#{key}")
    end
    def self.defaults
      {
          app: 'info',
          hook: 'info',
          build: 'info',
          git: 'info',
      }
    end
    def level(type, level)
      instance_variable_set(:"@#{type}", level)
    end
  end
  class Cli
    include Section
    SECTIONS = {
        config: {
            mkpass: [:length, :symbols]
        },
        server: {
            # no host or port since those are set via Webhook
            # webhook:
            #   host: 127.0.0.1
            #   port: 9090
            #
          # TODO: Find options to put here
        },
    }
    def initialize(config)
      # super
      config.each do |sec, values|
        instance_variable_set(StrExt.mkatvar(sec), values) unless values.empty?
      end
    end
    def server
      CliClasses::Server.new(@server)
    end
    def config
      CliClasses::Config.new(@config)
    end
    def inspect
      wanted = instance_variables
      outputs = []
      wanted.each do |meth|
        outputs << "#{StrExt.rematvar(meth)}=#{instance_variable_get(meth)}"
      end
      "#<SiteHook::Cli #{outputs.join(' ')}>"
    end
  end

  ##
  # Internal Classes for each section
  #
  # Projects:
  #   Project
  # Cli:
  #   Command
  #
  class Project
    attr_reader :name, :src, :dst, :host, :repo, :hookpass
    def initialize(name, config)
      @name = name.to_s
      config.each do |option,value|
        instance_variable_set(StrExt.mkatvar(option), value)
      end
    end
    def inspect
      outputs = []
      instance_variables.each do |sym|
        outputs << "#{StrExt.rematvar(sym)}=#{instance_variable_get(sym)}"
      end
      "#<SiteHook::Projects::Project #{outputs.join(' ')}>"
    end
  end
  class CliClasses
    class Config
      def initialize(config)
        @configured_commands = {}
        config.each do |command, values|
          @configured_commands.store(command, values)
          puts command
          puts values
        end
      end
      def mkpass
        Command.new(:mkpass, @configured_commands[:mkpass])
      end

      def inspect
        outputs = []
        @configured_commands.each do |m, body|
          outputs << "#{m}=#{body}"
        end
        "#<SiteHook::Cli::Config #{outputs.join(' ')}>"
      end
    end
    class Server
      def initialize(config)
        @kconfigured_commands = {}
        config.each do |command, values|
          @configured_commands[command] = Command.new(name, options)
        end
      end
    end
    class Command
      attr_reader :name
      def initialize(name, options)
        options.each do |option,value|
          self.class.define_method(option) do

          end
        end
      end
      def inspect
        # Bleh
      end
    end
    class CommandOption
      def initialize(option, value)
      end
    end
  end
end