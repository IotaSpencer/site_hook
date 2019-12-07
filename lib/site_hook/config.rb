require 'site_hook/paths'
require 'yaml'
require 'site_hook/string_ext'
require 'site_hook/prelogger'
module SiteHook
  class Config
    @@config = {}
    # def self.validate(config)
    #   config.each do |section, hsh|
    #     case section.to_s
    #     when 'webhook'
    #       if hsh['port']
    #         port_validity = [
    #             hsh['port'].respond_to?(:to_i),
    #             hsh['port'].is_a?(Integer)
    #         ].drop_while(&:!)
    #         SiteHook::PreLogger.debug port_validity
    #       else
    #         raise InvalidConfigError 'webhook', index
    #       end
    #       if hsh['host']
    #         host_validity = [
    #             hsh['host'].respond_to?(:to_s)
    #
    #         ]
    #       end
    #       [port_validity]
    #     when 'log_levels'
    #
    #     when 'cli'
    #     when 'projects'
    #     when 'out'
    #       if hsh['out'].keys
    #         hsh['out'].keys.each do |key|
    #           case key
    #           when 'discord'
    #           when 'irc'
    #           else
    #             raise InvalidConfigError 'out', "#{key} is an invalid out service"
    #           end
    #         end
    #       end
    #     else
    #       raise UnknownFieldError section
    #     end
    #   end
    # end

    def inspect
      meths    = %i[webhook log_levels cli projects]
      sections = {}
      meths.each do |m|
        sections[m] = self.class.send(m).inspect
      end
      secs = []
      sections.each { |name, instance| secs << "#{name}=#{instance}" }
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
      rescue Errno::ENOENT
        PreLogger.error 'ENOENT'
        raise SiteHook::NoConfigError.new @@filename
      rescue NoMethodError
        PreLogger.error @@filename.empty?
      end
    rescue NoConfigError
      #SiteHook::Commands::ConfigClass.invoke()
      PreLogger.error SiteHook::Commands::ConfigClass.methods
    rescue NeitherConfigError
      #SiteHook::Commands::ConfigClass.invoke(:gen)
      PreLogger.error SiteHook::Commands::ConfigClass.methods
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
  class Webhook
    def initialize(config)
      config.each do |option, value|
        sec = StrExt.mkatvar(option)
        self.instance_variable_set(:"#{sec}", value)
      end
    end

    def host
      @host || '0.0.0.0'
    end

    def port
      @port || 9090
    end

    def inspect
      "#<SiteHook::Webhook host=#{host} port=#{port}>"
    end

  end
  class Projects
    def initialize(config)
      config.each do |project, options|
        instance_variable_set(StrExt.mkatvar(StrExt.mkvar(project)), Project.new(project, options))
      end
    end

    def inspect

      output = []
      instance_variables.each do |project|
        output << "#{StrExt.rematvar(project)}=#{instance_variable_get(project).inspect}"
      end
      "#<SiteHook::Projects #{output.join(' ')}"
    end

    def find_project(name)
      public_vars = instance_variables.reject do |project_var|
        instance_variable_get(project_var).private
      end
      project_obj = public_vars.select do |project|
        project == StrExt.mkatvar(StrExt.mkvar(name))
      end
      project_obj = project_obj.join
      begin
        instance_variable_get(project_obj)
      rescue NameError
        nil
      end

    end

    def get(project)
      if instance_variables.empty?
        return :no_projects
      end
      vars = instance_variables.select do |name|
        name == StrExt.mkatvar(StrExt.mkvar(project))
      end
      if vars.empty?
        return :not_found
      end
      obj = vars.join
      begin
        instance_variable_get(obj)
      rescue NameError => e
        return :not_found
      end
    end

    #
    # Collect project names that meet certain criteria
    def collect_public
      public_vars     = instance_variables.reject do |project_var|
        instance_variable_get(project_var).private
      end
      public_projects = []
      public_vars.each do |var|
        public_projects << instance_variable_get(var)
      end
      public_projects
    end

    def to_h
      projects = {}
      each do |project|
        projects[project.name] = {}
        %i[src dst repo host private].each do |option|
          projects[project.name][option] = project.instance_variable_get(StrExt.mkatvar(option))
        end

      end
      projects
    end

    def each(&block)
      len1 = instance_variables.length
      x    = 0
      while x < len1
        base = self
        yield instance_variable_get(instance_variables[x])
        x += 1
      end
    end

    def self.length
      instance_variables.length
    end
  end
  class LogLevels
    attr :app, :hook, :build, :git

    def initialize(config)

      LogLevels.defaults.each do |type, level|
        if config.fetch(type.to_s, nil)
          level(type.to_s, config.fetch(type.to_s))
        else
          level(type.to_s, level)
        end
      end
    end

    def to_h
      output_hash = {}
      wanted      = %i[app hook build git]
      wanted.each do |logger|
        output_hash.store(logger, instance_variable_get(StrExt.mkatvar(logger)))
      end
      output_hash
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
          app:   'info',
          hook:  'info',
          build: 'info',
          git:   'info',
      }
    end

    def level(type, level)
      instance_variable_set(:"@#{type}", level)
    end
  end
  class Cli
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
      wanted  = instance_variables
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
    attr_reader :name, :src, :dst, :host, :repo, :hookpass, :private, :config

    def initialize(name, config)
      @name = name.to_s
      config.each do |option, value|
        instance_variable_set(StrExt.mkatvar(option), value)
        if instance_variable_get(StrExt.mkatvar(:config))
          # variable exists in configuration
        else
          instance_variable_set(StrExt.mkatvar(:config), '_config.yml')
        end
        if config.fetch('private', nil)
          instance_variable_set(StrExt.mkatvar(option), value) unless instance_variables.include?(:@private)
        else
          instance_variable_set(StrExt.mkatvar('private'), false)
        end
      end
    end

    def inspect
      outputs = []
      instance_variables.each do |sym|
        outputs << "#{StrExt.rematvar(sym)}=#{instance_variable_get(sym)}"
      end
      "#<SiteHook::Project #{outputs.join(' ')}>"
    end
  end
  class CliClasses
    class Config
      def initialize(config)
        @configured_commands = {}
        config.each do |command, values|
          @configured_commands.store(command, values)
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
        @configured_commands = {}
        config.each do |command, values|
          @configured_commands.store(command, values)
        end
      end

      def listen
        Command.new(:listen, @configured_commands[:listen])
      end

      def inspect
        outputs = []
        @configured_commands.each do |m, body|
          outputs << "#{m}=#{body}"
        end
        "#<SiteHook::Cli::Server #{outputs.join(' ')}>"
      end
    end
    class Command
      attr_reader :name

      def initialize(name, options)
        @name = name
        options.each do |option, value|
          self.class.define_method(option.to_sym) do
            return value

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