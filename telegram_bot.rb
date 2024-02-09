# frozen_string_literal: true

# telegram_bot.rb

require 'telegram/bot'
require 'dotenv/load'
require 'byebug'
require 'logger'

class MyTelegramBot
  class << self
    def respond_to_message(bot, message)
      case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id,
                             text: "Hello, #{message.from.first_name}! Welcome to the Telegram Bot:)")
        when '/help'
        bot.api.send_message(chat_id: message.chat.id, text: "You can use /start, /help, /bets, /top, /sport, /date for more options.")

      when '/bets'
        bot.api.send_message(chat_id: message.chat.id,
                             text: "You've chosen to view bets by bets")
      when '/top'
        bot.api.send_message(chat_id: message.chat.id,
                             text: "You've chosen to view bets by topbets")
      when '/sport'
        bot.api.send_message(chat_id: message.chat.id,
                             text: "You've chosen to view bets by sport")
      when '/date'
        bot.api.send_message(chat_id: message.chat.id,
                             text: "You've chosen to view bets by date")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "You said: #{message.text}")
      end
    end

    def run(token)
      Telegram::Bot::Client.run(token) do |bot|
        bot.listen do |message|
          respond_to_message(bot, message) if message.text
          byebug
        end
      end
    end
  end
end

MyTelegramBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
