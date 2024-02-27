# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'httparty'
require 'logger'
require 'byebug'
require 'yaml'
require 'erb'
require 'logger'
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

# Helper class to allow Logger to write to multiple outputs
class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each { |target| target.write(*args) }
  end

  def close
    @targets.each(&:close)
  end
end

# Set up the logger
LOG_FILE = File.join('logs', 'bot.log')
LOGGER = Logger.new(MultiIO.new(File.open(LOG_FILE, 'a'), STDOUT), 'daily')
LOGGER.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{severity} -- #{msg}\n"
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
        LOGGER.info("Received update: #{update.to_json}")
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
      LOGGER.info("Responding to message from user #{message.from.id}: '#{message.text}'")
      BotHelpers.validate_presence([bot, message], ['bot', 'message'])

      text = message.text&.downcase

      case text
        when '/start'
          display_start_message(bot, message)
          send_helpful_message(bot, message)
        when '/help', '/payments', '/sports_betting', '/promotion', '/events', '/scheduler'
          send_helpful_message(bot, message)
        when '/invoice'
          display_invoice_options(bot, message)
        else
          send_default_message(bot, message)
      end
      rescue ArgumentError => e
        LOGGER.error("ArgumentError - respond_to_message: #{e.message}")
        handle_error(e, 'ArgumentError - respond_to_message')
      rescue StandardError => e
        LOGGER.error("StandardError - respond_to_message: #{e.message}")
        handle_error(e, 'Error - respond_to_message')
      end

    def handle_callback_query(bot, callback_query)
      BotHelpers.validate_presence([bot, callback_query], ['bot', 'callback_query'])
      LOGGER.info("Handling callback query from user #{callback_query.from.id} - #{callback_query.from.username}: '#{callback_query.data}'")

      begin
        case callback_query.data
        when 'worldwide'
          send_worldwide_invoice(bot, callback_query)
        when 'ethiopia'
          handle_ethiopia_callback_query(bot, callback_query)
        when 'complete_payment'
          verify_chapa_transaction(callback_query.data)
        else
          send_invalid_option_message(bot, callback_query)
        end
      rescue => e
        LOGGER.error("Error in handle_callback_query: #{e.class}: #{e.message}")
        bot.api.send_message(chat_id: callback_query.from.id, text: 'There was an error processing your request. Please try again.')
      end
    end

    def handle_precheckout_query(bot, pre_checkout_query)
    BotHelpers.validate_presence([bot, pre_checkout_query], ['bot', 'pre_checkout_query'])
    LOGGER.info("Handling pre-checkout query from user #{pre_checkout_query.from.id}")
    bot.api.answer_pre_checkout_query(pre_checkout_query.id, true)
  rescue => e
    LOGGER.error("Error in handle_precheckout_query: #{e.class}: #{e.message}")
  end

  def handle_shipping_query(bot, shipping_query)
    BotHelpers.validate_presence([bot, shipping_query], ['bot', 'shipping_query'])
    LOGGER.info("Handling shipping query from user #{shipping_query.from.id}")
    provide_shipping_options(bot, shipping_query)
  rescue => e
    LOGGER.error("Error in handle_shipping_query: #{e.class}: #{e.message}")
  end

  def display_start_message(bot, message)
    start_message = UI_STRINGS['start_message'] % { first_name: message.from.first_name }
    LOGGER.info("Sending start message to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: start_message)
  rescue => e
    LOGGER.error("Error in display_start_message: #{e.class}: #{e.message}")
  end

  def send_helpful_message(bot, message)
    helpful_message = UI_STRINGS['help_message']
    LOGGER.info("Sending helpful message to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: helpful_message)
  rescue => e
    LOGGER.error("Error in send_helpful_message: #{e.class}: #{e.message}")
  end

  def send_invalid_option_message(bot, callback_query)
    invalid_option_text = 'Invalid option selected.'
    LOGGER.info("Notifying user #{callback_query.from.id} of invalid option")
    bot.api.send_message(chat_id: callback_query.from.id, text: invalid_option_text)
  rescue => e
    LOGGER.error("Error in send_invalid_option_message: #{e.class}: #{e.message}")
  end

  def send_default_message(bot, message)
    default_response = UI_STRINGS['default_response'] % { message_text: message.text }
    LOGGER.info("Sending default response to user #{message.from.id}")
    bot.api.send_message(chat_id: message.chat.id, text: default_response)
  rescue => e
    LOGGER.error("Error in send_default_message: #{e.class}: #{e.message}")
  end

  def send_worldwide_invoice(bot, callback_query)
    invoice_details = InvoiceUtils.setup_worldwide_invoice_details
    LOGGER.info("Sending worldwide invoice to chat #{callback_query.message.chat.id}")
    InvoiceUtils.dispatch_invoice(bot, callback_query.message.chat.id, invoice_details)
  rescue => e
    LOGGER.error("Error in send_worldwide_invoice: #{e.class}: #{e.message}")
  end


  def handle_ethiopia_callback_query(bot, callback_query)
  LOGGER.info("Handling Ethiopia callback query from user #{callback_query.from.id}")
  user_email = ENV['USER_EMAIL']
  user_phone_number = ENV['USER_PHONE_NUMBER']
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
    callback_url: "#{ENV['CALLBACK_URL']}?tx_ref=#{generated_tx_ref_test}&&chat_id=#{callback_query.from.id}",
    return_url: ENV['RETURN_URL']
  }

  LOGGER.info("Initiating Chapa transaction for user #{callback_query.from.id} with payload: #{payload}")

  # Initialize the Chapa transaction
  response = initiate_chapa_transaction(payload)

  # Check the response and handle accordingly
  if response.code == 200
    checkout_url = response.parsed_response['data']['checkout_url']
    display_ethiopia_payment_options(bot, callback_query.from.id, checkout_url, payload)
    LOGGER.info("Chapa transaction initiated successfully for user #{callback_query.from.id}")
  else
    LOGGER.error("Error initializing Chapa transaction for user #{callback_query.from.id}: #{response.body}")
    bot.api.send_message(chat_id: callback_query.from.id, text: 'There was an error initializing the payment. Please try again.')
  end
rescue => e
  LOGGER.error("Exception in handle_ethiopia_callback_query for user #{callback_query.from.id}: #{e.message}")
end

def display_ethiopia_payment_options(bot, chat_id, checkout_url, _payload)
  LOGGER.info("Displaying Ethiopia payment options for chat #{chat_id}")
  message_text = UI_STRINGS['ethiopia_payment_options']['message_text'] % { checkout_url: checkout_url }
  complete_payment_button_text = UI_STRINGS['ethiopia_payment_options']['complete_payment_button']

  keyboard = [Telegram::Bot::Types::InlineKeyboardButton.new(text: complete_payment_button_text, callback_data: 'complete_payment', url: checkout_url)]
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [keyboard])
  bot.api.send_message(chat_id: chat_id, text: message_text, reply_markup: markup)
rescue => e
  LOGGER.error("Exception in display_ethiopia_payment_options for chat #{chat_id}: #{e.message}")
end

def display_invoice_options(bot, message)
  LOGGER.info("Displaying invoice options for user #{message.from.id}")
  invoice_option_message = UI_STRINGS['invoice_option_message']
  options = [
    Telegram::Bot::Types::InlineKeyboardButton.new(text: '🌍አለምአቀፍ | Worldwide', callback_data: 'worldwide'),
    Telegram::Bot::Types::InlineKeyboardButton.new(text: '🇪🇹ኢትዮጲያ | Ethiopia', callback_data: 'ethiopia')
  ]
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [options])
  bot.api.send_message(chat_id: message.chat.id, text: invoice_option_message, reply_markup: markup)
rescue => e
  LOGGER.error("Exception in display_invoice_options for user #{message.from.id}: #{e.message}")
end

private

  def generate_tx_ref(prefix = 'chewatatest-')
    random_number = rand(1000..9999).to_s
    tx_ref = "#{prefix}#{random_number}"
    LOGGER.info("Generated transaction reference: #{tx_ref}")
    tx_ref
  rescue => e
  LOGGER.error("Exception in generate_tx_ref: #{e.message}")
    nil # Return nil or handle as necessary
  end

  def initiate_chapa_transaction(payload)
    LOGGER.info("Initiating Chapa transaction with payload: #{payload}")
    response = HTTParty.post(
      ENV['CHAPA_TRANSACTION_ENDPOINT'], # Using the environment variable for the endpoint
      headers: {
        'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}", # Using the secret key from environment variables
        'Content-Type' => 'application/json'
      },
      body: payload.to_json
    )
    LOGGER.info("Chapa transaction response: #{response.parsed_response}")
    response
  rescue => e
  LOGGER.error("Exception in initiate_chapa_transaction: #{e.message}")
    nil # Return nil or handle as necessary
  end

  def verify_chapa_transaction(tx_ref)
    LOGGER.info("Verifying Chapa transaction with tx_ref: #{tx_ref}")
    url = "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}#{tx_ref}" # Combine the environment variable and transaction reference
    headers = {
      'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" # Using the secret key from environment variables
    }
    response = HTTParty.get(url, headers: headers)
    LOGGER.info("Chapa transaction verification response: #{response.parsed_response}")
    response.parsed_response
  rescue => e
  LOGGER.error("Exception in verify_chapa_transaction: #{e.message}")
    nil # Return nil or handle as necessary
  end

  def provide_shipping_options(bot, shipping_query)
    LOGGER.info("Providing shipping options for query #{shipping_query.id}")
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
    LOGGER.info("Shipping options provided for query #{shipping_query.id}")
  rescue => e
  LOGGER.error("Exception in provide_shipping_options: #{e.message}")
  end

end
  # Remember to implement all the helper methods needed for the logic above.

MyTelegramBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
