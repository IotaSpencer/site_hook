require 'site_hook/config'
require 'grape'
module SiteHook
  class ServerWebhook < Grape::API
    before do
      header 'X-Robots-Tag', 'noindex'
      remote_addr      = headers['REMOTE_ADDR']
      cf_connecting_ip = env.fetch('HTTP_CF_CONNECTING_IP', nil)
      ip               = cf_connecting_ip || remote_addr
      SiteHook::Log.access.log "#{ip} - #{request.path}:"
    end
    after do
      SiteHook::Log.access.log "#{status}"
    end
    namespace :webhook do

      get '/' do
        {status: 1, message: 'invalid endpoint'}
      end
      route_param :hook_name do
        desc 'Return project info'
        get do
          project = SiteHook::Config.projects.find_project(params[:hook_name])
          if project.nil?
            {status: 1, message: "project is private or doesn't exist"}
          else
            {status: 0, project: params}
          end
        end
        post do
          service = nil
          project = SiteHook::Config.projects.get(params[:hook_name])
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
  end

end