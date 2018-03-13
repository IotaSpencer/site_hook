require 'open3'
require 'site_hook/logger'

module SiteHook
  module Senders
    class JekyllBuild
      attr :jekyll_source, :build_dest

      # @param [String,Pathname] jekyll_source Path to the Jekyll Source for the site
      # @param [String,Pathname] build_dest Absolute path to where jekyll should build
      def initialize(jekyll_source, build_dest, logger:)
        @jekyll_source = jekyll_source
        @build_dest = build_dest
        @log = logger
      end

      def grab_jekyll_version
        begin
          stdout_str, stderr_str, status = Open3.capture3('jekyll --version')
        rescue Errno::ENOENT
          @log.log.error('Jekyll not installed! Gem and Webhook will not function')
        end
      end

      def build
        stdout_str, stderr_str, status = Open3.capture3("jekyll build --source #{@jekyll_source} --destination #{Pathname(@build_dest).to_path}")
      end
    end
  end
end
