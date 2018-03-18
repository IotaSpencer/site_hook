require 'thor'

require 'site_hook/config_class'
module SiteHook
  def self.log_levels
    default = {
      'hook' => 'info',
      'build' => 'info',
      'git' => 'info',
      'app' => 'info'
    }
    begin
      log_level = YAML.load_file(Pathname(Dir.home).join('.jph-rc')).fetch('log_levels')
      if log_level
        log_level
      end
    rescue KeyError
      default
    rescue Errno::ENOENT
      default
    end
  end

  class CLI < Thor
    map %w[--version -v] => :__print_version
    desc '--version, -v', 'Print the version'

    # Prints version string
    # @return [NilClass] nil
    def __print_version
      puts SiteHook::VERSION
    end

    method_option(:log_levels, type: :hash, banner: 'LEVELS', default: SiteHook.log_levels)

    desc 'start', 'Start SiteHook'

    def start

      SiteHook.mklogdir unless Pathname(Dir.home).join('.jph', 'logs').exist?
      SiteHook::Webhook.run!
    end

    subcommand(:config, ConfigClass)
  end
end
