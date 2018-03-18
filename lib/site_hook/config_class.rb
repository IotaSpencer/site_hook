require 'thor'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class ConfigClass < Thor
    YML = open(Pathname(Dir.home).join('.jph-rc'), 'r')

    desc 'list QUERY [options]', 'List configured options'

    def list
      puts YML.read
    end
  end
end
