require 'thor'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class ConfigClass < Thor
    YML = RecursiveOpenStruct.new(YAML.load_file(Pathname(Dir.home).join('.jph-rc')))

    desc 'list QUERY [options]', 'List configured options'
    def list(query = nil)
      case query
      when '-a', 'all'
        YML.each do |directive, hsh|
          say directive
          say hsh
        end
      end
    end
  end
end
