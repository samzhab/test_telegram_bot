# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'httparty'
require 'logger'
require 'byebug'
require 'yaml'
require 'erb'

# Module for helper methods
module BotHelpers
  def self.validate_presence(values, names)
    Array(values).zip(Array(names)).each do |value, name|
      raise ArgumentError, "Invalid or missing #{name}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end

# Module for invoice-related utilities
module InvoiceUtils
    def self.setup_worldwide_invoice_details
      config = YAML.load(ERB.new(File.read('invoice_details.yml')).result)
      config['setup_worldwide_invoice_details']
    end

    def self.dispatch_invoice(bot, chat_id, invoice_details)
      bot.api.send_invoice(chat_id: chat_id, **invoice_details)
    end
end

module ErrorHandler
  def handle_error(error, context = 'General')
    error_message = "#{context}: #{error.message}"
    puts error_message
  end
end


class MyTelegramBot
  include BotHelpers  # This mixes in BotHelpers methods as instance methods
  include InvoiceUtils  # This mixes in InvoiceUtils methods as instance methods
  include ErrorHandler
  extend ErrorHandler

  class << self

    def load_ui_strings
      file_path = 'ui_strings.yml'
      if File.exist?(file_path)
        YAML.load_file(file_path)
      else
        error_message = "Error: UI strings file not found at #{file_path}"
        handle_error(RuntimeError.new(error_message), 'load_ui_strings')
        {}
      end
    end

    def run(token)
      BotHelpers.validate_presence(token, 'token')
      bot_instance = new  # Create an instance of MyTelegramBot
      Telegram::Bot::Client.run(token) do |bot|
        bot_instance.bot_listen(bot)  # Call instance method 'bot_listen' on the created instance
      end
      rescue StandardError => e
        handle_error(e, 'run')  # Assuming handle_error is correctly defined to handle such errors
    end

  end

  UI_STRINGS = load_ui_strings

    def bot_listen(bot)
      bot.listen do |update|
        case update
        when Telegram::Bot::Types::Message
          respond_to_message(bot, update)
        when Telegram::Bot::Types::PreCheckoutQuery
          handle_precheckout_query(bot, update)
        when Telegram::Bot::Types::ShippingQuery
          handle_shipping_query(bot, update)
        when Telegram::Bot::Types::CallbackQuery
          handle_callback_query(bot, update)
        end
      end
    end

    def respond_to_message(bot, message)
      BotHelpers.validate_presence([bot, message], ['bot', 'message'])

      text = message.text&.downcase

      case text
        when '/start'
          display_start_message(bot, message)
        when '/help', '/bets', '/top', '/sport', '/date'
          send_helpful_message(bot, message)
        when '/invoice'
          display_invoice_options(bot, message)
        else
          send_default_message(bot, message)
      end
      rescue ArgumentError => e
        handle_error(e, 'ArgumentError - respond_to_message')
      rescue StandardError => e
        handle_error(e, 'Error - respond_to_message')
      end

    def handle_callback_query(bot, callback_query)
      BotHelpers.validate_presence([bot, callback_query], ['bot', 'callback_query'])

      case callback_query.data
      when 'worldwide'
        send_worldwide_invoice(bot, callback_query)
      when 'ethiopia'
        handle_ethiopia_callback_query(bot, callback_query)
      when 'complete_payment'
        verify_chapa_tragnsaction(tx_ref)
      else
        send_invalid_option_message(bot, callback_query)
      end
    end

    def handle_precheckout_query(bot, pre_checkout_query)
      BotHelpers.BotHelpers.validate_presence([bot, pre_checkout_query], %w[bot pre_checkout_query])
      bot.api.answer_pre_checkout_query(pre_checkout_query.id, true)
    end

    def handle_shipping_query(bot, shipping_query)
      BotHelpers.BotHelpers.validate_presence([bot, shipping_query], %w[bot shipping_query])
      provide_shipping_options(bot, shipping_query)
    end

    def display_start_message(bot, message)
      start_message = UI_STRINGS['start_message'] % { first_name: message.from.first_name }
      bot.api.send_message(chat_id: message.chat.id, text: start_message)
    end

    def send_helpful_message(bot, message)
      helpful_message = UI_STRINGS['help_message']
      bot.api.send_message(chat_id: message.chat.id, text: helpful_message)
    end

    def send_invalid_option_message(bot, callback_query)
      invalid_option_text = 'Invalid option selected.'
      bot.api.send_message(chat_id: callback_query.from.id, text: invalid_option_text)
    end

    def send_default_message(bot, message)
      default_response = UI_STRINGS['default_response'] % { message_text: message.text }
      bot.api.send_message(chat_id: message.chat.id, text: default_response)
    end

    def send_worldwide_invoice(bot, callback_query)
      invoice_details = InvoiceUtils.setup_worldwide_invoice_details
      InvoiceUtils.dispatch_invoice(bot, callback_query.message.chat.id, invoice_details)
    end

    def handle_ethiopia_callback_query(bot, callback_query)
      # Assuming you have user email and phone number stored or queried earlier
      user_email = 'ali@gmail.com' # Replace with actual user email
      user_phone_number = '09837477458' # Replace with actual user phone number
      generated_tx_ref_test = generate_tx_ref
      # Construct payload for Chapa API
      payload = {
        amount: '1000', # Set this based on your pricing logic
        currency: 'ETB',
        email: user_email,
        first_name: callback_query.from.first_name,
        last_name: callback_query.from.last_name,
        phone_number: user_phone_number,
        tx_ref: generated_tx_ref_test,
        callback_url: "https://3b16-144-48-38-22.ngrok-free.app/chapa_payment_verification?tx_ref=#{generated_tx_ref_test}&&chat_id=#{callback_query.from.id}", # Your server endpoint to verify transaction
        return_url: 'https://t.me/chatID_retreiver_bot' # Redirect here after payment
      }
      # Initialize the Chapa transaction
      response = initiate_chapa_transaction(payload)

      # Check the response and handle accordingly
      if response.code == 200
        checkout_url = response.parsed_response['data']['checkout_url']
        display_ethiopia_payment_options(bot, callback_query.from.id, checkout_url, payload)
      else
        puts "Error initializing Chapa transaction: #{response.body}"
        bot.api.send_message(chat_id: callback_query.from.id,
                             text: 'There was an error initializing the payment. Please try again.')
      end
      # payload{"tx_ref"}
    end

    def display_ethiopia_payment_options(bot, chat_id, checkout_url, _payload)
      message_text = UI_STRINGS['ethiopia_payment_options']['message_text'] % { checkout_url: checkout_url }
      complete_payment_button_text = UI_STRINGS['ethiopia_payment_options']['complete_payment_button']

      keyboard = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: complete_payment_button_text,
                                                       callback_data: 'complete_payment',
                                                       url: checkout_url)
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [keyboard])
      bot.api.send_message(chat_id: chat_id, text: message_text, reply_markup: markup)
    end

  # Implementation for displaying invoice options
    def display_invoice_options(bot, message)
      invoice_option_message = UI_STRINGS['invoice_option_message']
      options = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: '🌍አለምአቀፍ | Worldwide', callback_data: 'worldwide'),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: '🇪🇹ኢትዮጲያ | Ethiopia', callback_data: 'ethiopia')
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [options])
      bot.api.send_message(chat_id: message.chat.id, text: invoice_option_message, reply_markup: markup)
    end

  private

    def generate_tx_ref(prefix = 'chewatatest-')
      random_number = rand(1000..9999).to_s
      "#{prefix}#{random_number}"
    end

    def initiate_chapa_transaction(payload)
      HTTParty.post(
        ENV['CHAPA_TRANSACTION_ENDPOINT'], # Using the environment variable for the endpoint
        headers: {
          'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}", # Using the secret key from environment variables
          'Content-Type' => 'application/json'
        },
        body: payload.to_json
      )
    end

    def verify_chapa_transaction(tx_ref)
      url = "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}#{tx_ref}" # Combine the environment variable and transaction reference
      headers = {
        'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" # Using the secret key from environment variables
      }
      response = HTTParty.get(url, headers: headers)
      response.parsed_response
    end

    # Implementation for providing shipping options
    def provide_shipping_options(bot, shipping_query)
      shipping_options = [
        Telegram::Bot::Types::ShippingOption.new(
          id: 'standard',
          title: 'Standard Shipping',
          prices: [Telegram::Bot::Types::LabeledPrice.new(label: 'Standard', amount: 1000)]
        ),
        Telegram::Bot::Types::ShippingOption.new(
          id: 'express',
          title: 'Express Shipping',
          prices: [Telegram::Bot::Types::LabeledPrice.new(label: 'Express', amount: 2000)]
        )
      ]
      bot.api.answer_shipping_query(
        shipping_query_id: shipping_query.id,
        ok: true,
        shipping_options: shipping_options
      )
    end

end
  # Remember to implement all the helper methods needed for the logic above.

MyTelegramBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
