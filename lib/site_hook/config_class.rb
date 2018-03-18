require 'thor'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class ConfigClass < Thor
    YML = RecursiveOpenStruct.new(YAML.load_file(Pathname(Dir.home)))

    def list(query = nil)
      case query
      when '-a', 'all'
        YML.each do |directive, hsh|
          puts directive
          puts hsh
        end
      end
    end
  end
end
