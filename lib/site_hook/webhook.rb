##########
# -> File: /home/ken/RubymineProjects/site_hook/lib/site_hook/webhook.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 1/10/2018 21:35:44
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########

require 'sinatra'

module SiteHook
  class Webhook < Sinatra::Base
    HOOKLOG = SiteHook::HookLogger::HookLog.new(SiteHook::Logs.log_levels['hook']).log
    BUILDLOG = SiteHook::HookLogger::BuildLog.new(SiteHook::Logs.log_levels['build']).log
    APPLOG = SiteHook::HookLogger::AppLog.new(SiteHook::Logs.log_levels['app']).log
    JPHRC = YAML.load_file(Pathname(Dir.home).join('.jph', 'config'))

    set port: JPHRC.fetch('port', 9090)
    set bind: '127.0.0.1'
    set server: %w[thin]
    set quiet: true
    set raise_errors: true
    set views: Pathname(SiteHook::Paths.lib_dir).join('site_hook', 'views')
    set :public_folder, Pathname(SiteHook::Paths.lib_dir).join('site_hook', 'static')
    use SassHandler
    use CoffeeHandler

#
    # @param [String] body JSON String of body
    # @param [String] sig Signature or token from git service
    # @param [String] secret User-defined verification token
    # @param [Boolean] plaintext Whether the verification is plaintext
    def self.verified?(body, sig, secret, plaintext:, service:)
      if plaintext
        sig == secret
      else
        case service
        when 'gogs'
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body)
            APPLOG.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body)}"
            true
          end
        when 'github'
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
            APPLOG.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)}"
            true
          end
        end

      end
    end

    get '/' do
      halt 403, { 'Content-Type' => 'text/html' }, '<h1>See <a href="/webhooks/">here</a> for the active webhooks</h1>'
    end

    get '/webhooks.json', provides: :json do
      content_type 'application/json'
      public_projects = JPHRC['projects'].select do |_project, hsh|
        (hsh.fetch('private', nil) == false) || hsh.fetch('private', nil).nil?
      end
      result = {}
      public_projects.each do |project, hsh|
        result[project] = {}
        hsh.delete('hookpass')
        result[project].merge!(hsh)
      end
      headers 'Content-Type' => 'application/json', 'Accept' => 'application/json'
      json result, layout: false
    end

    get '/webhooks/?' do
      haml :webhooks, locals: { 'projects' => JPHRC['projects'] }
    end

    get '/webhook/*' do
      if params[:splat]
        pass
      else
        halt 405, { 'Content-Type' => 'application/json' }, { message: 'GET not allowed' }.to_json
      end
    end
    post '/webhook/:hook_name/?' do
      service = nil
      request.body.rewind
      req_body = request.body.read
      js = RecursiveOpenStruct.new(JSON.parse(req_body))

      projects = JPHRC['projects']
      begin
        project = projects.fetch(params[:hook_name])
      rescue KeyError => e
        halt 404, { 'Content-Type' => 'application/json' }, { message: 'no such project', status: 1 }.to_json
      end
      plaintext = false
      signature = nil
      event = nil
      gogs = request.env.fetch('HTTP_X_GOGS_EVENT', nil)
      unless gogs.nil?
        event = 'push' if gogs == 'push'
      end
      github = request.env.fetch('HTTP_X_GITHUB_EVENT', nil)
      unless github.nil?
        event = 'push' if github == 'push'
      end
      gitlab = request.env.fetch('HTTP_X_GITLAB_EVENT', nil)
      unless gitlab.nil?
        event = 'push' if gitlab == 'push'
      end

      events = { 'github' => github, 'gitlab' => gitlab, 'gogs' => gogs }
      if events['github'] && events['gogs']
        events['github'] = nil
      end
      events_m_e = events.values.one?
      case events_m_e
      when true
        event = 'push'
        service = events.select { |_key, value| value }.keys.first
      when false
        halt 400, { 'Content-Type': 'application/json' }, { message: 'events are mutually exclusive', status: 'failure' }.to_json

      else
        halt 400,
             { 'Content-Type': 'application/json' },
             'status': 'failure', 'message': 'something weird happened'
      end
      if event != 'push'
        if event.nil?
          halt 400, { 'Content-Type': 'application/json' }, { message: 'no event header' }.to_json
        end
      end
      case service
      when 'gitlab'
        signature = request.env.fetch('HTTP_X_GITLAB_TOKEN', '')
        plaintext = true
      when 'github'
        signature = request.env.fetch('HTTP_X_HUB_SIGNATURE', '').sub!(/^sha1=/, '')
        plaintext = false

      when 'gogs'
        signature = request.env.fetch('HTTP_X_GOGS_SIGNATURE', '')
        plaintext = false
      end
      if Webhook.verified?(req_body.to_s, signature, project['hookpass'], plaintext: plaintext, service: service)
        BUILDLOG.info 'Building...'

        jekyllbuild = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], BUILDLOG)
        jekyll_status = jekyllbuild
        case jekyll_status

        when 0
          status 200
          headers 'Content-Type' => 'application/json'
          body { { 'status': 'success' }.to_json }
        when -1, -2, -3
          halt 400, { 'Content-Type' => 'application/json' }, { 'status': 'exception', error: jekyll_status.fetch(:message).to_s }

        end

      else
        halt 403, { 'Content-Type' => 'application/json' }, { message: 'incorrect secret', 'status': 'failure' }.to_json
      end
    end
    post '/webhook/?' do
      halt 403, { 'Content-Type' => 'application/json' }, { message: 'pick a hook', error: 'root webhook hit', 'status': 'failure' }.to_json
    end
  end
end
