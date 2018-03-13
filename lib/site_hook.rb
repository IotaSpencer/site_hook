require 'site_hook/version'
require 'site_hook/sender'
require 'site_hook/logger'
require 'site_hook/cli'
require 'sinatra'
require 'sinatra/json'
require 'yaml'

module SiteHook
  #  class << self
  #    attr_accessor :opts
  #  end
  module_function

  def options; @opts end
  def options=(v); @opts = v end

  class Webhook < Sinatra::Base
    HookLog = SiteHook::HookLogger::HookLog.new(SiteHook.log_levels['hook'])
    BuildLog = SiteHook::HookLogger::BuildLog.new(SiteHook.log_levels['build'])
    set port: 9090
    set bind: '127.0.0.1'

    def Webhook.verified?(body, hub_sig, secret)
      if hub_sig == OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
        true
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
      sig = request.env['HTTP_X_HUB_SIGNATURE'].sub!(/^sha1=/, '')
      jph_rc = YAML.load_file(Pathname(Dir.home).join('.jph-rc'))
      projects = jph_rc['projects']
      begin
        project = projects.fetch(params[:hook_name])
      rescue KeyError => e
        halt 404, {'Content-Type' => 'application/json'}, {message: 'no such project', status: 1}.to_json
      end
      if Webhook.verified?(req_body.to_s, sig, project['hookpass'])
        BuildLog.log.debug 'Attempting to build...'
        jekyllbuild = SiteHook::Senders::Jekyll.build(project['src'], project['dst'], logger: BuildLog)
        status 200
        headers 'Content-Type' => 'application/json'
        body {
          {"message": "success"}.to_json
        }
      else
        halt 403, {'Content-Type' => 'application/json'}, {message: 'incorrect secret'}.to_json
      end
    end
    post '/webhook/?' do
      halt 403, {'Content-Type' => 'application/json'}, {message: 'pick a hook', error: 'root webhook hit'}.to_json
    end
  end
end
