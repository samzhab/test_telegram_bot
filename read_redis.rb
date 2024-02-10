require 'redis'
require 'json'

# Assuming environment variables are used to configure Redis
# Load dotenv in a non-Rails project to use environment variables from .env file
require 'dotenv/load'

# Initialize Redis client
redis = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB'], password: ENV['REDIS_PASSWORD'])

# Use SCAN to fetch keys for the first 10 matches
cursor = "0"
match_keys = []
loop do
  cursor, keys = redis.scan(cursor, match: 'match:*', count: 10)
  match_keys.concat(keys)
  break if match_keys.length >= 3 || cursor == "0"
end
match_keys = match_keys.take(3)

# Extract and print details for each match
match_keys.each do |key|
  match_data = redis.get(key)
  match_details = JSON.parse(match_data)

  puts "Match ID: #{match_details['id']}"
  puts "Home Team: #{match_details['home_team']}"
  puts "Away Team: #{match_details['away_team']}"
  puts "Schedule: #{match_details['schedule']}"
  puts "League ID: #{match_details['league_id']}"
  puts "Odds:"
  match_details['odds'].each do |odd|
    puts "  Odd ID: #{odd['odd_id']}, Value: #{odd['odd_value']}, Bet Type ID: #{odd['bet_type_id']}, Bet Group ID: #{odd['bet_group_id']}"
  end
  puts "-" * 20 # Separator for readability
end

