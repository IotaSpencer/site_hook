##########
# -> File: /home/ken/RubymineProjects/site_hook/lib/site_hook/webhook.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 1/10/2018 21:35:44
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########
require 'scorched'
require 'rack'
require 'site_hook/logger'
module SiteHook
  class Server < Scorched::Controller
    config[:logger] = false
    config[:show_http_error_pages] = false
    middleware << proc do
      use Rack::Static, :url => ['public']
    end
    render_defaults.merge!(
                       dir: SiteHook::Paths.lib_dir.join('site_hook','views'),
                       layout: :layout,
                       engine: :haml
    )
    config[:static_dir] = Pathname(SiteHook::Paths.lib_dir).join('site_hook', 'assets', 'public')

    #
    # @param [String] body JSON String of body
    # @param [String] sig Signature or token from git service
    # @param [String] secret User-defined verification token
    # @param [Boolean] plaintext Whether the verification is plaintext
    # @param [String] service service name
    def self.verified?(body, sig, secret, plaintext:, service:)
      if plaintext
        sig == secret
      else
        case service
        when 'gogs'
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body)
            SiteHook::Consts::APPLOG.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body)}"
            true
          end
        when 'github'
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
            SiteHook::Consts::APPLOG.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)}"
            true
          end
        else
          # This shouldn't happen
        end

      end
    end

    CONTENT_TYPE = 'Content-Type'
    APPLICATION_JSON = 'application/json'
    before do
      SiteHook::Log::App.info "#{request.ip} - #{request.path}:"
    end
    after do
      SiteHook::Log::App.info "#{response.status}"
    end
    get '/' do
      render :not_found
    end


    get '/webhooks.json' do
      content_type APPLICATION_JSON
      public_projects = SiteHook::Config.class_variable_get(:'@@projects').each do |project_name, klass|
        if klass.private
          SiteHook::Consts::APPLOG.log.debug("Not displaying #{project_name} since its private")
          next
        end

      end
      result          = {}
      public_projects.each do |project, hsh|
        result[project] = {}
        hsh.delete('hookpass')
        result[project].merge!(hsh)
      end
      headers CONTENT_TYPE => APPLICATION_JSON, 'Accept' => APPLICATION_JSON
      json result, layout: false
    end

    get '/webhooks/?' do
      render :webhooks, locals: {'projects' => SiteHook::Config.projects}
    end

    get '/webhook/:hook_name/?' do
      project = SiteHook::Config.projects[StrExt.mkvar(params[:hook_name])]
      if project.private
        haml :_404, locals: {'project_name' => params[:hook_name]}
      else
        haml :webhook, locals: {'host': project.host, 'repo': project.repo}
      end

    end
    post '/webhook/:hook_name/?' do
      service = nil
      request.body.rewind
      req_body = request.body.read
      js       = RecursiveOpenStruct.new(JSON.parse(req_body))
      project = SiteHook::Config.projects.send(StrExt.mkvar(params[:hook_name]))
      if project.nil?
        halt 404, {message: 'no such project', status: 1}.to_json
      end
      plaintext = false
      signature = nil
      event     = nil
      gogs      = request.env.fetch('HTTP_X_GOGS_EVENT', nil)
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

      events = {'github' => github, 'gitlab' => gitlab, 'gogs' => gogs}
      if events['github'] && events['gogs']
        events['github'] = nil
      end
      events_m_e = events.values.one?
      case events_m_e
      when true
        event   = 'push'
        service = events.select { |_key, value| value }.keys.first
      when false
        halt 400,
             {CONTENT_TYPE: APPLICATION_JSON},
             {message: 'events are mutually exclusive', status: 'failure'}.to_json

      else
        halt 400,
             {CONTENT_TYPE: APPLICATION_JSON},
             {'status': 'failure', 'message': 'something weird happened'}
      end
      if event != 'push' && event.nil?
        halt 400,
             {CONTENT_TYPE: APPLICATION_JSON},
             {message: 'no event header', status: 'failure'}.to_json
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
      else
        # This shouldn't happen
      end
      if Webhook.verified?(req_body.to_s, signature, project['hookpass'], plaintext: plaintext, service: service)
        SiteHook::Consts::BUILDLOG.info 'Building...'
        begin
          jekyll_status = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], SiteHook::Log::Build, options: {config: project['config']})
          case jekyll_status

          when 0
            status 200
            headers CONTENT_TYPE => APPLICATION_JSON
            body { {'status': 'success'}.to_json }
          when -1, -2, -3
            halt 400, {CONTENT_TYPE => APPLICATION_JSON}, {'status': 'exception', error: jekyll_status.fetch(:message).to_s}
          else
            # This shouldn't happen
          end
        rescue => e
          halt 500, {CONTENT_TYPE => APPLICATION_JSON}, {'status': 'exception', error: e.to_s}
        end
      else
        halt 403, {CONTENT_TYPE => APPLICATION_JSON}, {message: 'incorrect secret', 'status': 'failure'}.to_json
      end
    end
    post '/webhook/?' do
      halt 403, {CONTENT_TYPE => APPLICATION_JSON}, {message: 'pick a hook', error: 'root webhook hit', 'status': 'failure'}.to_json
    end
  end
end
