# lib/tasks/populate_redis.rake
require 'json'
require 'redis'
require 'dotenv'

namespace :data do
  desc "Populate Redis with detailed match info and active odds"
  task "populate_data" do
    Dotenv.load

    # Initialize Redis connection with environment variables
    redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'].to_i, password: ENV['REDIS_PASSWORD'])
    matches_file_path = File.join('lib', 'matches.json') # Update this to your actual file path

    begin
      matches_data = JSON.parse(File.read(matches_file_path))

      matches_data.each do |match|
        next unless match['win_odds']&.any? { |odd| odd['is_active'] }

        match_details = {
          id: match['id'],
          home_team: match['hom'],
          away_team: match['awy'],
          schedule: match['schedule'],
          league_id: match['league'],
          odds: match['win_odds'].select { |odd| odd['is_active'] }.map do |odd|
            {
              odd_id: odd['id'],
              odd_value: odd['odd'],
              bet_type_id: odd['bet_type'],
              bet_group_id: odd['bet_group']
            }
          end
        }

        redis_key = "match:#{match_details[:id]}"
        redis.set(redis_key, match_details.to_json)
      end

      puts "Matches and active odds populated in Redis."
    rescue JSON::ParserError => e
      puts "JSON Parsing Error: #{e.message}"
    rescue Errno::ENOENT => e
      puts "File not found: #{e.message}"
    rescue Redis::BaseConnectionError => e
      puts "Redis connection error: #{e.message}"
    rescue StandardError => e
      puts "An unexpected error occurred: #{e.message}"
    end
  end
end
