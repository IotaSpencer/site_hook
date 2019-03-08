require 'thor'
require 'random_password'
require 'site_hook/config_sections'
require 'site_hook/sender'
module SiteHook
  module Commands

    class JekyllClass < Thor
      # def __version
      # puts SiteHook::VERSION
      # end
      # map ['-v', '--version'] => __version

      desc 'build [options]', 'build sites'

      def build(project_name)
        if SiteHook::Paths.default_config.exist?
          begin
            project = SiteHook::Config.projects.send(StrExt.mkvar(project_name))
            jekyll_status = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], SiteHook::Log::Build, options: {config: project['config']})
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