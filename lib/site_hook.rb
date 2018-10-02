# frozen_string_literal: true

require 'site_hook/version'
require 'site_hook/sender'
require 'site_hook/logger'
require 'recursive-open-struct'
require 'site_hook/cli'
require 'sinatra'
require 'haml'
require 'sass'
require 'json'
require 'sinatra/json'
require 'yaml'
module SiteHook
  # rubocop:disable Metrics/ClassLength, Metrics/LineLength, MethodLength, BlockLength
  module Gem
    # class Info
    class Info
      def self.name
        'site_hook'
      end

      def self.constant_name
        'SiteHook'
      end

      def self.author
        'Ken Spencer <me@iotaspencer.me>'
      end
    end

    # Paths: Paths to gem resources and things
    class Paths
      def self.config
        Pathname(Dir.home).join('.jph', 'config').to_s
      end

      def self.logs
        Pathname(Dir.home).join('.jph', 'logs')
      end
    end
  end
  # class SassHandler (inherits from Sinatra::Base)
  class SassHandler < Sinatra::Base
    set :views, Pathname(app_file).dirname.join('site_hook', 'static', 'sass').to_s
    get '/css/*.css' do
      filename = params[:splat].first
      scss filename.to_sym, cache: false
    end
  end
  # class CoffeeHandler (inherits from Sinatra::Base)
  class CoffeeHandler < Sinatra::Base
    set :views, Pathname(app_file).dirname.join('site_hook', 'static', 'coffee').to_s
    get '/js/*.js' do
      filename = params[:splat].first
      coffee filename.to_sym
    end
  end
  # class Webhook (inherits from Sinatra::Base)
  class Webhook < Sinatra::Base
    HOOKLOG = SiteHook::HookLogger::HookLog.new(SiteHook.log_levels['hook']).log
    BUILDLOG = SiteHook::HookLogger::BuildLog.new(SiteHook.log_levels['build']).log
    APPLOG = SiteHook::HookLogger::AppLog.new(SiteHook.log_levels['app']).log
    JPHRC = YAML.load_file(Pathname(Dir.home).join('.jph-rc'))
    set port: JPHRC.fetch('port', 9090)
    set bind: '127.0.0.1'
    set server: %w[thin]
    set quiet: true
    set raise_errors: true
    set views: Pathname(app_file).dirname.join('site_hook', 'views')
    set :public_folder, Pathname(app_file).dirname.join('site_hook', 'static')
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
      github = request.env.fetch('HTTP_X_GITHUB_EVENT', nil)
      unless github.nil?
        event = 'push' if github == 'push'
      end
      gitlab = request.env.fetch('HTTP_X_GITLAB_EVENT', nil)
      unless gitlab.nil?
        event = 'push' if gitlab == 'push'
      end
      gogs = request.env.fetch('HTTP_X_GOGS_EVENT', nil)
      unless gogs.nil?
        event = 'push' if gogs == 'push'
      end
      events = { 'github' => github, 'gitlab' => gitlab, 'gogs' => gogs }
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
        jekyll_status = jekyllbuild.fetch(:status, 1)
        case jekyll_status

        when 0
          status 200
          headers 'Content-Type' => 'application/json'
          body { { 'status': 'success' }.to_json }
        when -1, -2, -3
          status 400
          headers 'Content-Type' => 'application/json'
          body do
            { 'status': 'exception', error: jekyll_status.fetch(:message).to_s }
          end
        end

      else
        halt 403, { 'Content-Type' => 'application/json' }, { message: 'incorrect secret', 'status': 'failure' }.to_json
      end
    end
    post '/webhook/?' do
      halt 403, { 'Content-Type' => 'application/json' }, { message: 'pick a hook', error: 'root webhook hit', 'status': 'failure' }.to_json
    end
  end
  # rubocop:enable Metrics/ClassLength, Metrics/LineLength, MethodLength, BlockLength
end
