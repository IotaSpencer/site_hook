require 'thor'
require 'random_password'
require 'site_hook/paths'
require 'site_hook/config_sections'
require 'tty-file'
module SiteHook
  module Commands

    class InitClass < Thor
      include Thor::Actions
      def all

      end
      def create_shrc_dir
        TTY::File.create_dir(SiteHook::Paths)
      end
      def create_shrc_logs_dir
        TTY::File.create_dir(Pathname.new(Dir.home).join('.shrc').join('logs')))
      end
      def create_config_sample
        TTY::File.create_file(Pathname.new(Dir.home).join('.shrc').join('config'), SiteHook::ConfigSections.all_samples)
      end
      def create_log_files(name)
        if 
        TTY::File.create_file(Pathname.new(Dir.home).join('.shrc').join('logs').join("#{name}.log"), "#{SiteHook::Templates::Logs.new.created_log_log_header}")
      end

    end
  end
end