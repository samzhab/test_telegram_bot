#!/bin/bash

# Path to your .env file
ENV_PATH=".env"

# Append Redis configuration to .env if not already present
if ! grep -q "REDIS_HOST=" "$ENV_PATH"; then
  echo "REDIS_HOST=localhost" >> "$ENV_PATH"
fi
if ! grep -q "REDIS_PORT=" "$ENV_PATH"; then
  echo "REDIS_PORT=6379" >> "$ENV_PATH"
fi
if ! grep -q "REDIS_DB=" "$ENV_PATH"; then
  echo "REDIS_DB=0" >> "$ENV_PATH"
fi

# Add Redis password configuration
if ! grep -q "REDIS_PASSWORD=" "$ENV_PATH"; then
  echo "REDIS_PASSWORD=your_redis_password_here" >> "$ENV_PATH"
fi

# Add COREDATA_JSON_URL and MATCHES_JSON_URL to .env if not already present
if ! grep -q "COREDATA_API_URL=" "$ENV_PATH"; then
  echo "COREDATA_API_URL=\"https://api.hulusport.com/sport-data/coredata/?ln=en\"" >> "$ENV_PATH"
fi

if ! grep -q "MATCHES_API_URL=" "$ENV_PATH"; then
  echo "MATCHES_API_URL=\"https://api.hulusport.com/sport-data/matches/?ln=en\"" >> "$ENV_PATH"
fi

# Optional: Configure Redis for persistence (AOF and/or RDB)
# This part assumes Redis is installed and the redis.conf file's path is known
REDIS_CONF="/etc/redis/redis.conf"
# Enable AOF persistence
sudo sed -i 's/^appendonly no/appendonly yes/' $REDIS_CONF
# Enable RDB persistence
sudo sed -i 's/^save ""/save 900 1 300 10 60 10000/' $REDIS_CONF

# Restart Redis to apply changes
sudo service redis-server restart

echo "Redis configuration and .env update completed."
