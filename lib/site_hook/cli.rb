require 'thor'
require 'site_hook/config_class'
require 'site_hook/server_class'
module SiteHook
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
    desc 'config SUBCOMMAND [OPTIONS]', 'Configure site_hook options'
    subcommand('config', SiteHook::ConfigClass)
    desc 'server SUBCOMMAND [OPTIONS]', 'Start the server'
    subcommand('server', SiteHook::ServerClass)


  end
end
