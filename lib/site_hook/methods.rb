require "site_hook/config"

module SiteHook
  class Methods
    def self.mklogdir
      path = SiteHook::Paths.logs
      if path.exist?
        STDERR.puts "'#{path}' exists, skipping.."
        # Path exists, don't do anything
      else
        STDERR.puts "'#{path}' does not exist. Creating..."
        FileUtils.mkpath(path.to_s)
      end
    end
    def self.mkconfdir
      path = SiteHook::Paths.dir
      if path.exist?
        STDERR.puts "'#{path}' exists, skipping.."
      else
        STDERR.puts "'#{path}' does not exist. Creating..."
      end
    end
    def self.mkconf
      path = SiteHook::Paths.config
      if path.exist?
        STDERR.puts "'#{path}' exists, skipping.."
      else
        STDERR.puts "'#{path}' does not exist. Creating..."
        TTY::File.create_file(path, SiteHook::ConfigSections.all_samples)
      end
    end

    # @param [String] hook_name the hook name as defined in the projects:... directive
    def self.find_hook(hook_name)
      project_objs = SiteHook::Configs::Projects.constants
      ret_val = project_objs.detect do |obj|
        SiteHook::Configs::Projects.const_get(obj.to_s).real_key.to_s == hook_name.to_s
      end
      if ret_val.nil?
        return nil
      elsif ret_val
        return SiteHook::Configs::Projects.const_get(ret_val)
      end
    end
  end
end
