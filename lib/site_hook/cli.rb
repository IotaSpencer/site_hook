require 'thor'
require 'highline'
require 'paint'
require 'pathname'
require 'site_hook/paths'
require 'site_hook/exceptions'
require 'site_hook/deprecate'
commands = SiteHook::Paths.lib_dir.join('site_hook/commands').children
commands.each do |filename|
  next if filename == '.' or filename == '..'
  f = filename.dirname
  require  "#{f + filename.basename('.*')}"
end

module SiteHook
  class App < Thor
    desc '--version, -v', 'returns version and exits'
    def __version
      puts SiteHook::VERSION
    end
    map ['-v', '--version'] => :__version

    desc 'config [subcommand] [options]', 'configure site_hook'
    subcommand('config', SiteHook::Commands::ConfigClass)
    desc 'server [subcommand] [options]', 'run server actions'
    subcommand('server', SiteHook::Commands::ServerClass)

  end
end