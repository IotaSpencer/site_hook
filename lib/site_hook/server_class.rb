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

  # *ServerClass*
  #
  # Holds all of the commands for the config subcommand
  class ServerClass < Thor
    method_option(:log_levels, type: :hash, banner: 'LEVELS', default: SiteHook::Logs.log_levels)
    desc 'listen', 'Start SiteHook'
    def listen
      SiteHook.mklogdir unless SiteHook::Paths.logs.exist?
      SiteHook::Webhook.run!
    end
  end
end
# rubocop:enable Metrics/AbcSize
