# frozen_string_literal: true

require 'redis'

uri = URI.parse(ENV['REDIS_URL'])
REDIS = Redis.new(host: uri.host, port: uri.port)
TTL = 60
