require "thor"
require "random_password"
require "site_hook/paths"
require "site_hook/config_sections"
require "tty-file"

module SiteHook
  module Commands
    class InitClass < Thor
      include Thor::Actions
      desc("all", "generate sample config and directories")

      def all
        invoke :create_shrc_dir
        invoke :create_shrc_logs_dir
        invoke :create_config_sample
      end

      desc "create_shrc_dir", "create the .shrc directory"

      def create_shrc_dir
        TTY::File.create_dir(SiteHook::Paths.dir)
      end

      desc "create_shrc_logs_dir", "create the .shrc/logs directory"

      def create_shrc_logs_dir
        TTY::File.create_dir(SiteHook::Paths.logs)
      end

      desc "create_config_sample", "create the config sample"

      def create_config_sample
        TTY::File.create_file(SiteHook::Paths.config, SiteHook::ConfigSections.all_samples)
      end
    end
  end
end
