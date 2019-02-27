require 'open3'
require 'site_hook/logger'
require 'git'
require 'paint'
module SiteHook
  module Senders
    class Jekyll
      attr :jekyll_source, :build_dest

      class Build
        def initialize(options)
          @options = options
        end

        JEKYLL_SOURCE_VAR = '@jekyll_source'

        def do_grab_version
          jekyll_source = Jekyll.instance_variable_get(JEKYLL_SOURCE_VAR)
          log = Jekyll.instance_variable_get('@log')
          begin
            stdout_str, status = Open3.capture2({'BUNDLE_GEMFILE' => Pathname(jekyll_source).join('Gemfile').to_path}, "jekyll --version --source #{jekyll_source}")
            log.info("Jekyll Version: #{stdout_str.chomp!}")
          rescue Errno::ENOENT
            log.fatal('Jekyll not installed! Gem and Webhook will not function')
            Process.kill('INT', Process.pid)
          end
        end

        def do_pull
          fakelog = SiteHook::HookLogger::FakeLog.new
          reallog = SiteHook::Log::Git.new(SiteHook::Config.log_levels.git)
          jekyll_source = Jekyll.instance_variable_get(JEKYLL_SOURCE_VAR)
          # build_dest = Jekyll.instance_variable_get('@build_dest')
          g = Git.open(jekyll_source, log: fakelog)
          g.pull
          fakelog.entries.each do |level, entries|
            entries.each { |entry| reallog.send(level.to_s, entry) }
          end
        end

        def do_build
          jekyll_source = Jekyll.instance_variable_get(JEKYLL_SOURCE_VAR)
          build_dest = Jekyll.instance_variable_get('@build_dest')
          log = Jekyll.instance_variable_get('@log')
          Open3.popen2e({'BUNDLE_GEMFILE' => Pathname(jekyll_source).join('Gemfile').to_path}, "bundle exec jekyll build --source #{Pathname(jekyll_source).realdirpath.to_path} --destination #{Pathname(build_dest).to_path} --config #{Pathname(jekyll_source).join(@options[:config])}") { |in_io, outerr_io, thr|
            pid = thr.pid

            outerr = outerr_io.read.lines
            outerr.each do |line|
              line = Paint.unpaint(line)
              line.squish!
              # Configuration file: /home/ken/sites/iotaspencer.me/_config.yml
              # Source: /home/ken/sites/iotaspencer.me
              # Destination: /var/www/iotaspencer.me
              # Incremental build: disabled. Enable with --incremental
              # Generating...
              # GitHub Metadata: No GitHub API authentication could be found.
              # Some fields may be missing or have incorrect data.
              # done in 6.847 seconds.
              # Auto-regeneration: disabled. Use --watch to enable.
              case
              when line =~ /done in .*/
                log.info(line)
              when line =~ /Generating.../
                log.info(line)
              when line =~ /Configuration file:|Source:|Destination:/
                log.debug(line)
              when line =~ /Incremental build: disabled.|Auto-regeneration/
                print ''
              else
                log.debug line
              end
            end
            thr.value
          }

        end
      end

      # @param [String,Pathname] jekyll_source Jekyll Source
      # @param [String,Pathname] build_dest Build Destination
      # @param [BuildLog] logger Build Logger Instance
      def self.build(jekyll_source, build_dest, logger, options:)
        @jekyll_source = jekyll_source
        @build_dest = build_dest
        @log = logger
        @options = options
        instance = self::Build.new(options)
        meths = [instance.do_grab_version, instance.do_pull, instance.do_build]
        begin
          meths.each do |m|
            @log.debug("Running #{m}")
            instance.send(m)
            @log.debug("Ran #{m}")
          end
          return {message: 'success', status: 0}
        rescue TypeError => e
          return {message: "#{e}", status: -1}
        rescue KeyError => e
          return {message: "#{e}", status: -2}
        rescue ArgumentError => e
          return {message: "#{e}", status: -3}
        end
      end
    end
  end
end
