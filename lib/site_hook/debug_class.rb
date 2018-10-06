##########
# -> File: /home/ken/RubymineProjects/site_hook/lib/site_hook/debug_class.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 6/10/2018 13:14:51
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########
require 'thor'

module SiteHook
  class FileExistsError < Exception
  end

  # *DebugClass*
  #
  # Holds all of the commands for the config subcommand
  class DebugClass < Thor

    desc 'paths [options]', "Return current paths for running site_hook"
    def paths
      home_gem_path = ENV['GEM_HOME']
      puts home_gem_path
      puts Pathname(::Gem.default_path.first).join('lib', 'site_hook')
      puts .exist?
    end
  end
end
