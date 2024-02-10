require 'redis'
require 'json'

# Assuming environment variables are used to configure Redis
# Load dotenv in a non-Rails project to use environment variables from .env file
require 'dotenv/load'

# Initialize Redis client
redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'], password: ENV['REDIS_PASSWORD'])

# Fetch all keys (adjust pattern as needed)
keys = redis.keys('*')

if keys.empty?
  puts "No keys found in Redis."
else
  puts "Reading contents of Redis DB:"
  keys.each do |key|
    value = redis.get(key)
    puts "#{key}: #{value}"
  end
end

