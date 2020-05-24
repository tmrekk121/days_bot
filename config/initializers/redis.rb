# frozen_string_literal: true

require 'redis'

uri = URI.parse(Rails.application.credentials.redis[:REDIS_URL])
REDIS = Redis.new(host: uri.host, port: uri.port)
