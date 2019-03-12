require 'thor'
require 'grape'
require 'grape-route-helpers'
require 'site_hook/webhook'
require 'rack'
require 'site_hook/config'
SiteHook::Config.new
module SiteHook
  module Commands
    class ServerClass < Thor
      # def __version
      # puts SiteHook::VERSION
      # end
      # map ['-v', '--version'] => __version
      method_option(:host, banner: 'HOST', aliases: ['-h'], type: :string, default: SiteHook::Config.webhook.host)
      method_option(:port, banner: 'PORT', aliases: ['-p'], type: :numeric, default: SiteHook::Config.webhook.port)
      desc 'listen [options]', ''
      def listen
        $threads << Thread.new do
          Rack::Server.start(
            app: SiteHook::Server,
            Host: options[:host],
            Port: options[:port],
            debug: true
          )
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