require 'thor'
require 'random_password'
require 'site_hook/config_sections'
module SiteHook
  module Commands

    class ConfigClass < Thor
      # def __version
      # puts SiteHook::VERSION
      # end
      # map ['-v', '--version'] => __version

      desc 'gen [-o]', 'generate a sample config, -o will output to STDOUT instead of to the default config location'
      method_option(:output, type: :boolean, default: false, aliases: '-o')
      def gen
        unless SiteHook::Paths.default_config.exist?
          if options[:output] == true
            say SiteHook::ConfigSections.all_samples
          else 
            File.open(SiteHook::Paths.config, 'w+') do |file|
              file.puts SiteHook::ConfigSections.all_samples
            end
          end
        else
          if options[:output] == true
            say SiteHook::ConfigSections.all_samples
          end
        end

      end

      desc 'mkpass [options]', 'create a hook password'
      method_option(:length, type: :numeric, banner: 'LENGTH', aliases: ['-l'], default: 20)

      def mkpass
        puts RandomPassword.new(length: options[:length]).generate
      end

      desc 'inspect [options]', 'output the configuration'
      def inspect
        puts SiteHook::Config.new.inspect
      end
    end
  end
end