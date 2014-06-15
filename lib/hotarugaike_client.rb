# coding: utf-8
require "json"
require "open-uri"
require 'net/http'
Net::HTTP.version_1_2

module Hotarugaike
  module Profile
    class Client
      attr_reader :entry_point
      attr_reader :service_id
      attr_reader :key
      
      def initialize(options)
        @entry_point = options[:entry_point]
        @service_id = options[:service_id]
        @key = options[:key]
        
        if [@entry_point, @service_id, @key].include?(nil)
          raise InvalidSettingsError.new
        end
      end
      
      def start_authentication
        timestamp = Time.now.to_i
        message = [@service_id, timestamp, 'authenticate'].join
        signature = sign(message)
        
        return "#{@entry_point}/authenticate?id=#{@service_id}&timestamp=#{timestamp}&signature=#{signature}"
      end
      
      def retrieve(key, timestamp, signature)
        if Time.at(timestamp.to_i) > 5.minutes.ago and 
          signature == sign([@service_id, key, timestamp, 'deliver'].join)
          
          # 認証キーが正常に引き渡されたので認証情報を要求する
          t = Time.now.to_i
          signature = sign([@service_id, key, t, 'retrieve'].join)
          src = open("#{@entry_point}/retrieve?id=#{@service_id}&key=#{key}&timestamp=#{t}&signature=#{signature}")
          user_info = JSON.parse(src.read)
          
          raise InvalidProfileExchangeError.new unless user_info['signature'] == sign([
            @service_id,
            user_info['profile_id'],
            user_info['domain_name'], user_info['screen_name'], user_info['nickname'],
            user_info['profile_text'], user_info['openid_url'], user_info['timestamp'],
            'retrieved'
          ].join)
        else
          # 認証キー引渡しのリクエストが不正
          raise InvalidProfileExchangeError.new
        end
        
        user_info
      end
      
      def edit
        return "#{@entry_point}?service_id=#{@service_id}"
      end
      
      def updated_profile(params)
        if params[:signature] == sign([
          @service_id, params[:profile_id],
          params[:nickname], params[:profile_text], 
          params[:timestamp], 'update'
        ].join) and Time.at(params[:timestamp].to_i) > 5.minutes.ago
        
          params
        else
          raise InvalidProfileExchangeError.new
        end
      end
      
      def logout
        "#{@entry_point}/logout?id=#{@service_id}"
      end
      
      private
      def sign(message)
        OpenSSL::HMAC::hexdigest(OpenSSL::Digest::SHA256.new, @key, message)
      end
    end
    
    class InvalidProfileExchangeError < RuntimeError; end
    class InvalidSettingsError < RuntimeError; end
  end
end

