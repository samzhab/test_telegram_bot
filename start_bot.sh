#!/bin/bash
source /home/admin/.rvm/scripts/rvm
rvm use 3.1.2@test_telegram_bot
exec ruby /home/admin/test_telegram_bot/telegram_bot.rb
