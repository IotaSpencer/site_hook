module SiteHook
  module Plugins
    class PluginBase
      # @param [String] name Plugin Name
      def _name(name = nil)
        @name = name if name
        @name
      end
      # @param [String] version Plugin Version
      def _version(version = nil)
        @version = version if version
        @version
      end
    end
  end
end