module SiteHook
  autoload :Paths, 'site_hook/paths'
  # Logs
  # Give logs related methods
  module Logs
    module_function
    def self.log_levels
      default = {
        'hook' => 'info',
        'build' => 'info',
        'git' => 'info',
        'app' => 'info'
      }
      begin
        log_level = YAML.load_file(SiteHook::Paths.config).fetch('log_levels')
        if log_level
          log_level
        end
      rescue KeyError
        default
      rescue Errno::ENOENT
        default
      end
    end
  end
end