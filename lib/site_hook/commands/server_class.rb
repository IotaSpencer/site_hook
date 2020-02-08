require 'thor'
require 'grape'
require 'grape-route-helpers'
require 'site_hook/webhook'
require 'thin'
require 'site_hook/config'
module SiteHook
  module Commands
    class ServerClass < Thor
      SiteHook::Config.config

      # def __version
      # puts SiteHook::VERSION
      # end
      # map ['-v', '--version'] => __version
      method_option(:host, banner: 'HOST', aliases: ['-h'], type: :string)
      method_option(:port, banner: 'PORT', aliases: ['-p'], type: :numeric)
      desc 'listen [options]', ''
      def listen
        host = SiteHook::Config.webhook.host
        port = SiteHook::Config.webhook.port
        if options['host']
          host = options['host']
        end
        if options['port']
          port = options['port']
        end

        $threads << Thread.new do
          PreLogger.debug options
          ::Thin::Server.start(host, port, SiteHook::Server, debug: true)
        end
        $threads << Thread.new do
          loop do
            case $stdin.gets
            when "reload\n"
              ::SiteHook::Config.reload!
            when "quit\n"
              $threads.each do |thr|
                thr == Thread.current ? exit(0) : thr.exit
              end
            end
          end
        end
        $threads.each(&:join)
      end
    end
  end
end
