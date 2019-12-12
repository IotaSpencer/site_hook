require 'paint/util'
module SiteHook

  # @returns SiteHook::DeprecationError
  class DeprecationError < SiteHookError
    # @params [String] msg message to return
    def initialize(msg)
      super(msg, 99)
    end
  end
  class Deprecation

    def self.deprecate(command, situation, instructions, continue)
      @@exe_name = command 
      @@str = "▼▼▼ [#{Paint['DEPRECATION ERROR', 'red', :bold]}] —— #{Paint['The following situation is deprecated', 'yellow', :bold, :blink]}! ▼▼▼"
      @@situation = situation
      @@str << "\n#{@@situation}"
      @@instructions = instructions
      @@str << "\n#{@@instructions}"

      return {msg: @@str, exit: !continue}
    end
    def self.deprecate_config(command)
      return self.deprecate(
          command,
          "'#{Paint[SiteHook::Paths.old_config.to_s, 'red']}' is deprecated in favor of '#{Paint[SiteHook::Paths.config, 'green']}'",
          <<-INSTRUCT,
              Please run `site_hook config upgrade-shrc", 'red', :blink]}` to rectify this.
              Once version 1.0.0 is released, '#{Paint["#{SiteHook::Paths.config}", 'green']}' will
              be the only config file option, and '#{Paint["#{SiteHook::Paths.old_config}", 'orange']}' will not be allowed.
              any existance of '#{Paint["#{Dir.home}/.jph", 'red']}' after the #{Paint['1.0.0', :bold]} release will result in an Exception being raised.
              #{"#{Paint['Once the exception is raised', 'red']}, site_hook will #{Paint['exit', 'red']} and return a #{Paint['99', 'red']} status code."}
          INSTRUCT
          true
      )
    end
    def self.raise_error(msg)
      raise DeprecationError.new(msg)
    end
  end
  class NotImplemented
    attr_reader :command_object

    def initialize(command)
      @command_object = command
      @exe_name = 'site_hook'
      @output_string = "Command `#{@exe_name} #{command.name_for_help.join(' ')}"
    end
    def self.declare(command)
      instance = self.new(command)
      instance.instance_variable_set(
          :'@output_string',
          "#{instance.instance_variable_get(:'@output_string')}` is not implemented currently")
      puts instance.instance_variable_get(:'@output_string')
    end
  end
end
