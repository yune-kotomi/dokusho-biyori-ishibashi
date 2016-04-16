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
        payload = {
          'id' => @service_id,
          'exp' => 5.minutes.from_now.to_i
        }
        token = JWT.encode(payload, @key)
        return "#{@entry_point}/authenticate?id=#{@service_id}&token=#{token}"
      end

      def retrieve(token)
        payload = JWT.decode(token, @key).first
        raise InvalidProfileExchangeError.new if payload['exp'].blank?

        payload['exp'] = 5.minutes.from_now.to_i
        token = JWT.encode(payload, @key)
        data = open("#{@entry_point}/retrieve?id=#{@service_id}&token=#{token}")

        payload = JWT.decode(data.read, @key).first
        raise InvalidProfileExchangeError.new if payload['exp'].blank?
        payload

      rescue JWT::VerificationError, JWT::DecodeError
        raise InvalidProfileExchangeError.new
      end

      def edit
        return "#{@entry_point}?service_id=#{@service_id}"
      end

      def updated_profile(token)
        JWT.decode(token, @key).first

      rescue JWT::VerificationError, JWT::DecodeError
        raise InvalidProfileExchangeError.new
      end

      def logout
        "#{@entry_point}/logout?id=#{@service_id}"
      end

      class InvalidSettingsError < RuntimeError; end
      class InvalidProfileExchangeError < RuntimeError; end
    end
  end
end
