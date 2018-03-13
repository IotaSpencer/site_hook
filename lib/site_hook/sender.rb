require 'open3'
require 'site_hook/logger'

module SiteHook
  module Senders
    class Jekyll
      attr :jekyll_source, :build_dest

      class Build

        # @param [String,Pathname] jekyll_source Path
        # @param [String,Pathname] build_dest path
        #        def initialize(jekyll_source, build_dest, logger:)
        #        end

        def do_grab_version
          begin
            stdout_str, stderr_str, status = Open3.capture3('jekyll --version')
          rescue Errno::ENOENT
            Jekyll.instance_variable_get('@log').log.error('Jekyll not installed! Gem and Webhook will not function')
          end
        end

        def do_build
          stdout_str, stderr_str, status = Open3.capture3("jekyll build --source #{@jekyll_source} --destination #{Pathname(@build_dest).to_path}")
        end
      end

      def self.build(jekyll_source, build_dest, logger:)
        @jekyll_source = jekyll_source
        @build_dest = build_dest
        @log = logger
        instance = self::Build.new
        meths = instance.methods.select { |x| x =~ /^do_/ }
        meths.each do |m|
          instance.method(m).call
        end
      end
    end
  end
end
