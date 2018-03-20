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
      #return if Pathname(Dir.home).join('.jph-rc').exist?

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
          "    src: /path/to/jekyll/site/source  # Directory you 'git pull' into",
          "    dst: /path/to/build/destination/  # The web root will be this folder",
          "    hookpass: SOMERANDOMSTRING        # set your Gitlab-Token or GitHub secret to this",
          "    private: true/false               # If the project is hidden from the public list of webhooks",
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
