require "thor"
require "random_password"
require "site_hook/config_sections"

module SiteHook
  module Commands
    class ConfigClass < Thor
      # def __version
      # puts SiteHook::VERSION
      # end
      # map ['-v', '--version'] => __version

      desc "mkpass [options]", "create a hook password"
      method_option(:length, type: :numeric, banner: "LENGTH", aliases: ["-l"], default: 20)

      def mkpass
        puts RandomPassword.new(length: options[:length]).generate
      end

      desc "inspect [options]", "output the configuration"

      def inspect
        puts SiteHook::Config.new.inspect
      end
    end
  end
end
