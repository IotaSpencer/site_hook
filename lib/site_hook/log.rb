require 'site_hook/configs/log_levels'
module SiteHook
  autoload :Paths, 'site_hook/paths'
  autoload :Config, 'site_hook/config'
  ##
  # Logs
  # Give logs related methods
  #

  module Logs
    module_function
    DEFAULT   = {
        'hook'  => 'info',
        'build' => 'info',
        'git'   => 'info',
        'app'   => 'info'
    }
    # @return [Hash] the log levels
    def self.log_levels
      puts SiteHook::Configs::LogLevels.methods
      log_level = SiteHook::Configs::LogLevels
      if log_level
        log_level
      end
    rescue KeyError
      DEFAULT
    rescue Errno::ENOENT
      DEFAULT
    end
  end
end