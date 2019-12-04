module SiteHook
  class ConfigSections
    def self.all_samples
      sections = self.constants
      @@sample = []
      sections.each do |section|
        @@sample << self.const_get(section).sample
      end
      puts @@sample
    end
    class Webhook
      def self.sample
        <<~WEBHOOK
          webhook:
            host: 127.0.0.1
            port: 9090

        WEBHOOK
      end

    end
    class LogLevels
      def self.sample
        <<~LOGLEVELS
          log_levels:
            # unknown, fatal, error, warn, info, debug
            app: info
            build: info
            git: info
            hook: info

        LOGLEVELS
      end
    end
    class Cli
      def self.sample
        <<~CLI
          cli:
            config:
              mkpass:
                length: 20
                symbols: false

        CLI
      end
    end
    class Projects
      def self.sample
        <<~PROJECTS
          projects:
            project1:
              config: _config.yml
              src: /path/2/site/source
              dst: /path/2/build/destination
              host: github.com
              repo: some/repo
              hookpass: SOMESECRETSTRING
              private: false

        PROJECTS
      end
    end
  end
end