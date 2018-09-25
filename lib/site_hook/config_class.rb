require 'thor'
require 'highline'
require 'random_password'
require 'yaml'
require 'recursive-open-struct'
module SiteHook
  class FileExistsError < Exception
  end

  # *ConfigClass*
  #
  # Holds all of the commands for the config subcommand
  class ConfigClass < Thor

    desc 'gen [options]', "Generate a example config file if one doesn't exist"
    # rubocop:disable Metrics/AbcSize
    def gen
      yaml = [
        '# fatal, error, warn, info, debug',
        'log_levels:',
        '  hook: info',
        '  build: info',
        '  git: info',
        '  app: info',
        'projects:',
        '  PROJECT.NAME:  # Use the name you put as your webhook url',
        '  # https://jekyllhook.example.com/webhook/PROJECT.NAME',
        "    src: /path/2/site/source   # Directory you 'git pull' into",
        '    dst: /path/2/destination/  # The web root will be this folder',
        "    host: git*.com             # The git service you're using for vcs",
        '    repo: USER/REPO            # The repo path on the git service',
        '    hookpass: SOMERANDOMSTRING # Gitlab-Token or GitHub secret, etc.',
        '    private: true/false        # hidden from the public list',
        ''
      ]
      jphrc = SiteHook::Gem::Paths.config
      if jphrc.exist?
        puts "#{jphrc} exists. Will not overwrite."
      else
        File.open(jphrc, 'w') do |f|
          yaml.each do |line|
            f.puts line
          end
        end
        say "Created #{jphrc}"
        say "You can now edit #{jphrc} and add your projects."
      end
    end
    desc 'bleh', 'bleh'
    def gen_project
      hl = HighLine.new
      hl.say "First What's the name of the project?"
      project_name = hl.ask('> ')

      hl.say "What's the source path? e.g. /home/#{ENV['USER']}/sites/site.tld"
      source_path = hl.ask('> ')

      hl.say 'Where is the web root? e.g. /var/www/sites/site.tld'
      dest_path = hl.ask('> ')

      hl.say 'The next things are for the public webhook list.'
      hl.say "\n"
      hl.say "\n"
      hl.say "What's the hostname of the git service? e.g. github.com,"
      hl.say "gitlab.com, git.domain.tld"
      git_host = hl.ask('> ')

      hl.say "What's the repo path? e.g. UserName/SiteName, UserName/site, etc."
      repo_path = hl.ask('> ')

      hl.say 'Is this repo allowed to be shown publically?'
      is_private = hl.agree('> ', true) ? true : false

      hl.say "Generating a hook password for you. If this one isn't wanted"
      hl.say 'then just change it afterwards.'
      hook_pass = RandomPassword.new(length: 20, symbols: 0).generate
      hl.say 'Done.'
      hl.say 'Outputting...'
      tpl = [
        "  #{project_name}:",
        "    src: #{source_path}",
        "    dst: #{dest_path}",
        "    hookpass: #{hook_pass}",
        "    host: #{git_host}",
        "    repo: #{repo_path}",
        "    private: #{is_private}"
      ]
      puts tpl
    end
  end
end
# rubocop:enable Metrics/AbcSize
