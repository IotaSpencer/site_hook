require 'site_hook/version'
require 'site_hook/sender'
require 'site_hook/logger'
require 'recursive-open-struct'
require 'site_hook/cli'
require 'sinatra'
require 'json'
require 'yaml'

module SiteHook
  class Webhook < Sinatra::Base
    @hooklog  = SiteHook::HookLogger::HookLog.new(SiteHook.log_levels['hook']).log
    @buildlog = SiteHook::HookLogger::BuildLog.new(SiteHook.log_levels['build']).log
    @applog   = SiteHook::HookLogger::AppLog.new(SiteHook.log_levels['app']).log
    @errorlog = SiteHook::HookLogger::ErrorLog.new.log

    set port: 9090
    set bind: '127.0.0.1'
    set server: %w(thin)
    set quiet: true
    set raise_errors: true
    set logger: @applog

    def Webhook.verified?(body, sig, secret, plaintext:)
      if plaintext
        if sig === secret
          true
        else
          false
        end
      else
        if sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
          @applog.debug "Secret verified: #{sig} === #{OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)}"
          true
        end
      end
    end

    get '/' do
      halt 403, {'Content-Type' => 'application/json'}, {message: 'no permission'}.to_json
    end
    get '/webhook/?' do
      halt 405, {'Content-Type' => 'application/json'}, {message: 'GET not allowed'}.to_json
    end
    post '/webhook/:hook_name' do
      request.body.rewind
      req_body = request.body.read
      js       = RecursiveOpenStruct.new(JSON.parse(req_body))
      jph_rc   = YAML.load_file(Pathname(Dir.home).join('.jph-rc'))
      projects = jph_rc['projects']
      begin
        project = projects.fetch(params[:hook_name])
      rescue KeyError => e
        halt 404, {'Content-Type' => 'application/json'}, {message: 'no such project', status: 1}.to_json
      end
      plaintext = false
      signature = nil
      event     = request.env.fetch('HTTP_X_GITLAB_EVENT', nil) || request.env.fetch('HTTP_X_GITHUB_EVENT', nil)
      @applog.info event.inspect
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
        @applog.debug(request.env.inspect)
      end
      if Webhook.verified?(req_body.to_s, signature, project['hookpass'], plaintext: plaintext)
        @buildlog.info 'Building...'
        jekyllbuild = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], logger: @buildlog)
        if jekyllbuild == 0
          status 200
          headers 'Content-Type' => 'application/json'
          body {
            {'message': 'success'}.to_json
          }
        else
          status 404
          headers 'Content-Type' => 'application/json'
          body {
            {'message': 'failure'}
          }
        end

      else
        halt 403, {'Content-Type' => 'application/json'}, {message: 'incorrect secret'}.to_json
      end
    end
    post '/webhook/?' do
      halt 403, {'Content-Type' => 'application/json'}, {message: 'pick a hook', error: 'root webhook hit'}.to_json
    end
  end
end
