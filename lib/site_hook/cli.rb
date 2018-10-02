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
      puts "Version: v#{SiteHook::VERSION}"
    end

    map %w(--gem-info --info --about) => :__gem_info
    desc '--gem-info, --info, --about', 'Print info on the gem.'
    def __gem_info
      say "Gem Name: #{SiteHook::Gem::Info.name}"
      say "Gem Constant: #{SiteHook::Gem::Info.constant_name}"
      say "Gem Author: #{SiteHook::Gem::Info.author}"
      say "Gem Version: v#{SiteHook::VERSION}"
    end

    method_option(:log_levels, type: :hash, banner: 'LEVELS', default: SiteHook.log_levels)
    desc 'start', 'Start SiteHook'
    def start

      SiteHook.mklogdir unless SiteHook::Gem::Paths.logs.exist?
      SiteHook::Webhook.run!
    end
    desc 'config SUBCOMMAND [OPTIONS]', 'Configure site_hook options'
    subcommand('config', SiteHook::ConfigClass)
  end
end
