require 'thor'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class FileExistsError < Exception
  end
  class ConfigClass < Thor
    YML = open(Pathname(Dir.home).join('.jph-rc'), 'r')

    desc 'list QUERY [options]', 'List configured options'

    def list
      puts YML.read
    end
    method_option :file, type: :boolean, banner: 'FILE', default: false, aliases: %w(-f)
    desc 'gen [options]', "Generate a example config file if one doesn't exist"
    def gen
      yaml = [
          "# fatal, error, warn, info, debug",
          "log_levels:",
          "  hook: info",
          "  build: info",
          "  git: info",
          "  app: info",
          "projects:",
          "  PROJECT.NAME:  # Use the name you put as your webhook url",
          "  # https://jekyllhook.example.com/webhook/PROJECT.NAME",
          "    src: /path/2/site/source   # Directory you 'git pull' into",
          "    dst: /path/2/destination/  # The web root will be this folder",
          "    host: git*.com             # The git service you're using for vcs",
          "    repo: USER/REPO            # The repo path on the git service",
          "    hookpass: SOMERANDOMSTRING # Gitlab-Token or GitHub secret, etc.",
          "    private: true/false        # hidden from the public list",
          "",
      ]
      if options[:file]
        jphrc = Pathname(Dir.home).join('.jph-rc')
        begin
          if jphrc.exist?
            raise SiteHook::FileExistsError "#{jphrc} exists. Will not overwrite."
          else
            open(jphrc, 'w') do |f|
              yaml.each do |line|
                f.puts line
              end
            end
            say "Created #{jphrc}"
            say "You can now edit #{jphrc} and add your projects."
          end
        rescue SiteHook::FileExistsError => e
          puts e
        end

      else
        puts yaml
      end

    end
  end
end
