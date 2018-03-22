require 'site_hook/version'
require 'site_hook/sender'
require 'site_hook/logger'
require 'recursive-open-struct'
require 'site_hook/cli'
require 'sinatra'
require 'haml'
require 'json'
require 'sinatra/json'
require 'yaml'

module SiteHook
  module Gem
    class Info
      def self.name
        'site_hook'
      end
      def self.constant_name
        'SiteHook'
      end
      def self.author
        %q(Ken Spencer <me@iotaspencer.me>)
      end
    end
  end

  class Webhook < Sinatra::Base
    HOOKLOG  = SiteHook::HookLogger::HookLog.new(SiteHook.log_levels['hook']).log
    BUILDLOG = SiteHook::HookLogger::BuildLog.new(SiteHook.log_levels['build']).log
    APPLOG   = SiteHook::HookLogger::AppLog.new(SiteHook.log_levels['app']).log
    JPHRC   = YAML.load_file(Pathname(Dir.home).join('.jph-rc'))
    set port: JPHRC.fetch('port', 9090)
    set bind: '127.0.0.1'
    set server: %w(thin)
    set quiet: true
    set raise_errors: true
    set views: Pathname(app_file).dirname.join('site_hook', 'views')

    # @param [String] body JSON String of body
    # @param [String] sig Signature or token from git service
    # @param [String] secret User-defined verification token
    # @param [Boolean] plaintext Whether the verification is plaintext
    def Webhook.verified?(body, sig, secret, plaintext:)
      if plaintext
        if sig === secret
          true
        else
          false
        end
      else
        if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
          APPLOG.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)}"
          true
        end
      end
    end

    get '/' do
      halt 403, {'Content-Type' => 'text/html'}, "<h1>See <a href=\"/webhooks/\">here</a> for the active webhooks</h1>"
    end

    get '/webhooks.json', provides: :json do
      public_projects = JPHRC['projects'].select do |project, hsh|
        hsh.fetch('private', nil) == false or hsh.fetch('private', nil).nil?
      end
      json public_projects

    end

    get '/webhooks/?' do
      haml :webhooks, locals: {'projects' => JPHRC['projects']}
    end

    get '/webhook/*' do
      if params[:splat]
        pass
      else
        halt 405, {'Content-Type' => 'application/json'}, {message: 'GET not allowed'}.to_json
      end

    end
    post '/webhook/:hook_name/?' do
      request.body.rewind
      req_body = request.body.read
      js       = RecursiveOpenStruct.new(JSON.parse(req_body))

      projects = JPHRC['projects']
      begin
        project = projects.fetch(params[:hook_name])
      rescue KeyError => e
        halt 404, {'Content-Type' => 'application/json'}, {message: 'no such project', status: 1}.to_json
      end
      plaintext = false
      signature = nil
      event     = request.env.fetch('HTTP_X_GITLAB_EVENT', nil) || request.env.fetch('HTTP_X_GITHUB_EVENT', nil)
      APPLOG.info event.inspect
      if event != 'push'
        if event.nil?
          halt 400, {'Content-Type' => 'application/json'}, {message: 'no event header'}.to_json
        end
      end
      case
      when request.env.fetch('HTTP_X_GITLAB_EVENT', nil)
        signature = request.env.fetch('HTTP_X_GITLAB_TOKEN', '')
        plaintext = true
      when request.env.fetch('HTTP_X_GITHUB_EVENT', nil)

        signature = request.env.fetch('HTTP_X_HUB_SIGNATURE', '').sub!(/^sha1=/, '')
        plaintext = false
      else
        APPLOG.debug(request.env.inspect)
      end
      if Webhook.verified?(req_body.to_s, signature, project['hookpass'], plaintext: plaintext)
        BUILDLOG.info 'Building...'
        jekyllbuild = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], BUILDLOG)
        jekyll_status = jekyllbuild.fetch(:status, 1) == 0
        case jekyll_status

        when 0
          status 200
          headers 'Content-Type' => 'application/json'
          body {
            {'message': 'success'}.to_json
          }
        when -1, -2, -3
          status 400
          headers 'Content-Type' => 'application/json'
          body {
            {'message': 'exception', error: "#{jekyll_status.fetch(:message)}"}
          }
        end

      else
        halt 403, {'Content-Type' => 'application/json'}, {message: 'incorrect secret', status: 1}.to_json
      end
    end
    post '/webhook/?' do
      halt 403, {'Content-Type' => 'application/json'}, {message: 'pick a hook', error: 'root webhook hit'}.to_json
    end
  end
end
