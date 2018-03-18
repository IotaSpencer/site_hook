require 'thor'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class ConfigClass < Thor
    YML = RecursiveOpenStruct.new(YAML.load_file(Pathname(Dir.home).join('.jph-rc')))

    desc 'list QUERY [options]', 'List configured options'

    def list
      YML.each do |directive, hsh|
        STDOUT.puts directive
        STDOUT.puts hsh
      end
    end
  end
end
