##########
# -> File: /home/ken/RubymineProjects/site_hook/lib/site_hook/config_class.1.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 1/10/2018 21:45:36
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########
require 'thor'
module SiteHook
  autoload :Webhook, 'site_hook/webhook'
  JPHRC = YAML.load_file(Pathname(Dir.home).join('.jph', 'config'))
  # *ServerClass*
  #
  # Holds all of the commands for the config subcommand
  class ServerClass < Thor
    method_option(:log_levels, type: :hash, banner: 'LEVELS', default: SiteHook::Logs.log_levels)
    method_option :host, type: :string, banner: 'BINDHOST', default: JPHRC.fetch('host', '127.0.0.1')
    method_option :port, type: :string, banner: 'BINDPORT', default: JPHRC.fetch('port', 9090)
    desc 'listen', 'Start SiteHook'
    def listen
      SiteHook.mklogdir unless SiteHook::Paths.logs.exist?
      SiteHook::Webhook.set_bind(options[:host], options[:port])
      SiteHook::Webhook.run!
    end
  end
end
# rubocop:enable Metrics/AbcSize
