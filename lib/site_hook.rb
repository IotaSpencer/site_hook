require 'sinatra'
require 'sinatra/json'
require 'yaml'
require "site_hook/version"
require 'site_hook/sender'
module SiteHook
  class Webhook < Sinatra::Base
    set port: 9090
    set bind: '0.0.0.0'

    def Webhook.verified?(body, hub_sig, secret)
      dig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, secret, body)
      puts "body => #{body}"
      puts "secret => #{secret}"
      puts "hub_sig => #{hub_sig}"
      puts "dig => #{dig}"
      if hub_sig == dig
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
      sig      = request.env['HTTP_X_HUB_SIGNATURE']
      projects = YAML.load_file(Pathname(Dir.home).join('.jph-rc'))['projects']
      begin
      project  = projects.fetch(params[:hook_name])
      rescue KeyError => e
        halt 404, {'Content-Type' => 'application/json'}, {message: 'no such project', status: 1}.to_json
      end

      if Webhook.verified?(req_body.to_s, sig, project['hookpass'])
        #SiteHook::Sender.send('doodie')
        status 200
        headers 'Content-Type' => 'application/json'
        body {
          json "{\"message\": \"success\"}"
        }
      else
        halt 403, {'Content-Type' => 'application/json'}, {message: 'incorrect secret'}.to_json
      end
    end
    post '/webhook/?' do
      halt 403, {'Content-Type' => 'application/json'}, {message: 'pick a hook', error: 'root webhook hit'}.to_json
    end
  end
  module CLI
    def run
      SiteHook::Webhook.new

    end
  end
end
