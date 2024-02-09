
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

## Troubleshooting

Refer to the service status and logs for any errors. Common issues include incorrect paths, permissions, or environment variables.

---
This README provides a basic overview for setting up a Telegram bot on an EC2 instance. Adjust paths, usernames, and versions according to your setup.
