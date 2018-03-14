require 'open3'
require 'site_hook/logger'
require 'git'

module SiteHook
  module Senders
    class Jekyll
      attr :jekyll_source, :build_dest

      class Build

        def do_grab_version
          jekyll_source = Jekyll.instance_variable_get('@jekyll_source')
          build_dest    = Jekyll.instance_variable_get('@build_dest')
          begin
            stdout_str, status = Open3.capture2({'BUNDLE_GEMFILE' => Pathname(jekyll_source).join('Gemfile').to_path}, "jekyll --version --source #{jekyll_source}")
            Jekyll.instance_variable_get('@log').info("Jekyll Version: #{stdout_str}")
          rescue Errno::ENOENT
            Jekyll.instance_variable_get('@log').fatal('Jekyll not installed! Gem and Webhook will not function')
            Process.kill('INT', Process.pid)
          end
        end

        def do_pull
          jekyll_source = Jekyll.instance_variable_get('@jekyll_source')
          build_dest    = Jekyll.instance_variable_get('@build_dest')
          g             = Git.open(jekyll_source, :log => SiteHook::HookLogger::GitLog.new(SiteHook.log_levels['git']).log)
          g.pull
        end

        def do_build
          jekyll_source = Jekyll.instance_variable_get('@jekyll_source')
          build_dest    = Jekyll.instance_variable_get('@build_dest')
          begin
            outerr_str, status = Open3.capture2e({'BUNDLE_GEMFILE' => Pathname(jekyll_source).join('Gemfile')}, "bundle exec jekyll build --source #{Pathname(jekyll_source).to_path} --destination #{Pathname(build_dest).to_path}")
            outerr_str.each do |line|
              Jekyll.instance_variable_get('@log').info(line)
            end

          rescue TypeError
          end
        end
      end

      def self.build(jekyll_source, build_dest, logger:)
        @jekyll_source = jekyll_source
        @build_dest    = build_dest
        @log           = logger
        instance       = self::Build.new
        meths          = instance.methods.select { |x| x =~ /^do_/ }

        meths.each do |m|
          @log.debug("Running #{m}")
          instance.method(m).call
          @log.debug("Ran #{m}")


        end
        return 0
      end
    end
  end
end
