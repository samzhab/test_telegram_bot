# lib/tasks/init_redis.rake

require 'redis'
require 'json'
require 'dotenv/load' # Ensure this is uncommented if you're using environment variables from .env

namespace :data do
  desc "Initialize Redis with dummy data"
  task :init_redis do
    begin
      # Initialize Redis
      redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'].to_i, password: ENV['REDIS_PASSWORD'])

      # Define your dummy data schema and data
      dummy_data = {
        "dummy:key:1" => { name: "John Doe", age: 30 }.to_json,
        "dummy:key:2" => { name: "Jane Doe", age: 25 }.to_json
        # Add more dummy data as needed
      }

      # Populate Redis with dummy data
      dummy_data.each do |key, value|
        redis.set(key, value)
      end

      puts "Redis initialization with dummy data completed."
    rescue => e
      puts "An error occurred during Redis initialization: #{e.message}"
    end
  end

  # Dummy task to satisfy the :environment dependency in non-Rails projects
  task :environment do
  end
end

