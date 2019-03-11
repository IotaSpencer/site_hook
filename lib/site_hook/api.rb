##########
# -> File: /site_hook/lib/site_hook/webhook.rb
# -> Project: site_hook
# -> Author: Ken Spencer <me@iotaspencer.me>
# -> Last Modified: 1/10/2018 21:35:44
# -> Copyright (c) 2018 Ken Spencer
# -> License: MIT
##########
require 'grape'
require 'rack'
require 'site_hook/logger'
require 'json'
require 'site_hook/mounts/webhook'

module SiteHook
  class Server < Grape::API
    format :json
    mount SiteHook::ServerWebhook
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
    APPLICATION_JSON = 'application/json'.freeze
    helpers do
      def logger
        SiteHook::Log.app
      end
    end
  end
end
