##########
# -> File: /site_hook/lib/site_hook/webhook.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 1/10/2018 21:35:44
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########
require 'rack'
require 'site_hook/logger'
require 'json'
require 'grape'
require 'grape-route-helpers'

module SiteHook
  class Server < Grape::API
    version nil
    prefix ''
    format :json

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
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body.chomp)
            SiteHook::Log.app.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, secret, body)}"
            true
          end
        when 'github'
          if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body.chomp)
            SiteHook::Log.app.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)}"
            true
          end
        else
          # This shouldn't happen
        end
      end
    end

    APPLICATION_JSON = 'application/json'
    before do
      remote_addr      = request.env['REMOTE_ADDR']
      cf_connecting_ip = request.env.fetch('HTTP_CF_CONNECTING_IP', nil)
      ip               = cf_connecting_ip || remote_addr
      SiteHook::Log.access.log "#{ip} - #{request.request_method} #{request.path}"
    end
    after do
      SiteHook::Log.access.log "#{status}"
    end
    resource '/webhook' do
      route_param :hook_name do
        get do

          project = SiteHook::Config.projects.find_project(StrExt.mkvar(params[:hook_name]))
          if project.nil?
            {message: 'project not found or private', status: 1, project: {}}
          else
            project_obj = {}
            %i[src dst repo host].each do |option|
              project_obj[option] = project.instance_variable_get(StrExt.mkatvar(option))
            end
            {project: project_obj}
          end
        end
        post do
          service = nil
          request.body.rewind
          req_body = request.body.read
          project  = SiteHook::Config.projects.get(StrExt.mkvar(params[:hook_name]))
          if project == :not_found
            halt 404, {message: 'no such project', status: 1}.to_json
          elsif project == :no_projects
            halt 500, {message: 'no projects defined', status: 2}.to_json
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
                 {message: 'events are mutually exclusive', status: 'failure'}.to_json

          else
            halt 400,
                 {'status': 'failure', 'message': 'something weird happened'}
          end
          if event != 'push' && event.nil?
            halt 400,
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
          if Server.verified?(req_body.to_s, signature, project.hookpass, plaintext: plaintext, service: service)
            SiteHook::Log.build.info 'Building...'
            begin
              jekyll_status = SiteHook::Senders::Jekyll.build(project.src, project.dst, SiteHook::Log.build, options: {config: project.config})
              case jekyll_status

              when 0
                {'status': 'success'}.to_json
              when -1, -2, -3
                halt 400, {'status': 'exception', error: jekyll_status.fetch(:message).to_s}
              else
                # This shouldn't happen
              end
            rescue => e
              halt 500, {'status': 'exception', error: e.to_s}.to_json
            end
          else
            halt 403, {message: 'incorrect secret', 'status': 'failure'}.to_json
          end
        end
      end
    end

    resource do
      get '/webhooks' do
        SiteHook::Config.projects.to_h
      end

    end
  end
end
