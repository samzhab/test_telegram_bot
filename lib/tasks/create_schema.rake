namespace :data do
  desc "Create Redis schema"
  task :create_schema do
    redis = Redis.new(
      host: ENV['REDIS_HOST'], 
      port: ENV['REDIS_PORT'], 
      db: ENV['REDIS_DB'], 
      password: ENV['REDIS_PASSWORD']
    )

    # Define schema for each table
    bet_groups_schema = {
      external_id: 1,
      name: "",
      is_locked: false,
      template: "",
      order: 0,
      has_param: false,
      is_print_available: false
    }

    bet_types_schema = {
      external_id: 1,
      name: "",
      is_locked: false
    }

    league_groups_schema = {
      external_id: 1,
      name: "",
      logo: "",
      order: 0,
      sport_type_id: 1
    }

    leagues_schema = {
      external_id: 1,
      name: "",
      order: 0,
      match_count: 0,
      item_count: 0,
      disabled: false,
      logo: "",
      league_group_id: 1,
      sport_type_id: 1
    }

    matches_schema = {
      external_id: 1,
      home_team: "",
      away_team: "",
      schedule: "",
      league_id: 1
    }

    odds_schema = {
      external_id: 1,
      value: 0.0,
      match_id: 1,
      bet_type_id: 1,
      bet_group_id: 1,
      is_active: true
    }

    sport_types_schema = {
      external_id: 1,
      name: "",
      order: 0,
      match_count: 0,
      logo: "",
      source: 1,
      compatibility: 0,
      sourceID: "",
      disabled: false,
      is_locked: false
    }

    # Store schemas in Redis
    redis.set("schema:bet_groups", bet_groups_schema.to_json)
    redis.set("schema:bet_types", bet_types_schema.to_json)
    redis.set("schema:league_groups", league_groups_schema.to_json)
    redis.set("schema:leagues", leagues_schema.to_json)
    redis.set("schema:matches", matches_schema.to_json)
    redis.set("schema:odds", odds_schema.to_json)
    redis.set("schema:sport_types", sport_types_schema.to_json)

    puts "Redis schema created successfully"
  end
end
