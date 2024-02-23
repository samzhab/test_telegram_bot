
# Telegram Bot Service Setup

This guide outlines the steps to set up and run a Telegram bot as a systemd service on an EC2 instance, ensuring it runs 24/7.

## Prerequisites

- A Telegram bot token obtained via [@BotFather](https://t.me/botfather).
- An EC2 instance with Ubuntu and Ruby installed.
- The `telegram-bot-ruby` gem for interacting with the Telegram Bot API.

## Step 1: Bot Script Preparation

Ensure your Telegram bot script (`telegram_bot.rb`) is ready and tested. The script should include a polling loop or webhook setup for receiving updates.

## Step 2: Wrapper Script Creation

Create a wrapper script (`start_bot.sh`) to handle the environment setup, including loading RVM and specifying the Ruby version:

```bash
#!/bin/bash
source /home/admin/.rvm/scripts/rvm
rvm use 3.1.2
exec ruby /home/admin/test_telegram_bot/telegram_bot.rb
```

Make sure to replace paths and Ruby version as necessary.

## Step 3: Systemd Service File

Create a systemd service file (`/etc/systemd/system/test_telegram_bot.service`) with the following content:

```ini
[Unit]
Description=Telegram Bot
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin/test_telegram_bot
ExecStart=/home/admin/test_telegram_bot/start_bot.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

## Step 4: Enabling and Starting the Service

Reload systemd, enable, and start your bot service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable test_telegram_bot.service
sudo systemctl start test_telegram_bot.service
```

## Step 5: Monitoring and Logs

Check the status of your service and review logs as needed:

```bash
sudo systemctl status test_telegram_bot.service
journalctl -u test_telegram_bot.service
```

## Integrating Redis

Our project now leverages Redis for enhanced data handling and caching capabilities, essential for optimizing performance and scalability.

### Setting Up Redis

#### Installation

Ensure Redis is installed on your development and production environments. Local development can typically use package managers like `brew` for macOS or `apt` for Ubuntu.

#### Configuration

Secure your Redis instance. Set a strong password and adjust settings for your needs in `redis.conf`, especially for production environments.

### Environment Configuration

Include Redis configuration in your `.env` file:

```makefile
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your_secure_password
```

### Populating Dummy Data with Rake Task

Use the provided rake task to initialize Redis with dummy data crucial for development and testing:

```shell
rake redis:init
```

This task ensures your environment mirrors production-like data, facilitating accurate testing and development.

### Testing

Mock Redis in your test suite to avoid impacting real data. Ensure your tests validate Redis interactions accurately, enhancing confidence in data integrity and application logic.


## Troubleshooting

Refer to the service status and logs for any errors. Common issues include incorrect paths, permissions, or environment variables.


## License
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

**Attribution**: This project is published by Samael (AI Powered), 2024.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.

No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.
