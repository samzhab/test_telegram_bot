# frozen_string_literal: true

require 'telegram/bot'
require 'dotenv/load'
require 'httparty'
require 'logger'
require 'byebug'

# Documentation for the MyTelegramBot class
module BotHelpers
  def self.validate_presence(values, names)
    Array(values).zip(Array(names)).each do |value, name|
      raise ArgumentError, "Invalid or missing #{name}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end

module InvoiceUtils
  def self.setup_worldwide_invoice_details
    {
      title: 'Global Product',
      description: 'A global product for international customers',
      payload: 'unique_payload_global',
      provider_token: ENV['PAYMENT_PROVIDER_STRIPE_TOKEN'],
      start_parameter: 'global-product',
      currency: 'USD',
      prices: [{ label: 'Product', amount: 5000 }],
      need_name: true,
      need_shipping_address: true,
      is_flexible: true
    }
  end

  def self.dispatch_invoice(bot, chat_id, invoice_details)
    bot.api.send_invoice(chat_id: chat_id, **invoice_details)
  end
end

# Main class for handling Telegram Bot functionality
class MyTelegramBot

  class << self
    include BotHelpers
    include InvoiceUtils

    def run(token)
      BotHelpers.validate_presence([token], ['token'])
      Telegram::Bot::Client.run(token) { |bot| bot_listen(bot) }
    rescue ArgumentError => e
      puts "ArgumentError: #{e.message}"
    rescue StandardError => e
      puts "Error: #{e.message}"
    end


    # -----------------Implementation for responding to various messages
    def respond_to_message(bot, message)
      BotHelpers.validate_presence([bot, message], %w[bot message])

      # Ensure text is not nil before attempting to downcase
      text = message.text&.downcase

      case text
      when '/start'
        display_start_message(bot, message)
      when '/help', '/bets', '/top', '/sport', '/date'
        send_helpful_message(bot, message)
      when '/invoice'
        display_invoice_options(bot, message)
      else
        # This will also handle the case where text is nil
        send_default_message(bot, message)
      end
    rescue ArgumentError => e
      puts "ArgumentError: #{e.message} in respond_to_message"
    rescue StandardError => e
      puts "Error: #{e.message} in respond_to_message"
    end

    private

    # -----------------
    def bot_listen(bot)
      bot.listen do |update|
        case update
        when Telegram::Bot::Types::Message
          puts 'Responding to MESSAGE....'
          respond_to_message(bot, update)
        when Telegram::Bot::Types::PreCheckoutQuery
          puts 'Handling PRECHECKOUT query....'
          handle_precheckout_query(bot, update)
        when Telegram::Bot::Types::ShippingQuery
          puts 'Handling SHIPPING query....'
          handle_shipping_query(bot, update)
        when Telegram::Bot::Types::CallbackQuery
          puts 'Handling CALLBACK query....'
          handle_callback_query(bot, update)
        end
      end
    end


    # -----------------Handling Ethiopia-specific pre-checkout query
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
        callback_url: "https://c071-85-204-70-92.ngrok-free.app/chapa_payment_verification?tx_ref=#{generated_tx_ref_test}&&chat_id=#{callback_query.from.id}", # Your server endpoint to verify transaction
        return_url: "https://t.me/chatID_retreiver_bot" # Redirect here after payment
    }
    # Initialize the Chapa transaction
    response = initiate_chapa_transaction(payload)

    # Check the response and handle accordingly
    if response.code == 200
        checkout_url = response.parsed_response['data']['checkout_url']
        display_payment_options(bot, callback_query.from.id, checkout_url, payload)
    else
        puts "Error initializing Chapa transaction: #{response.body}"
        bot.api.send_message(chat_id: callback_query.from.id, text: "There was an error initializing the payment. Please try again.")
    end
    # payload{"tx_ref"}
    end


    # Sending a custom message and payment button for Ethiopia-specific invoice
    def display_payment_options(bot, chat_id, checkout_url,payload)
      message_text = "Please complete your payment by selecting one of the available payment methods at the following link: #{checkout_url}. Note that the payment will be processed externally via Chapa."
      keyboard = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Complete Payment', callback_data: 'complete_payment', url: checkout_url)
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [keyboard])
      bot.api.send_message(chat_id: chat_id, text: message_text, reply_markup: markup)
    end


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


    def handle_chapa_callback(bot, chat_id, tx_ref)
    # Verify the transaction
    verification_result = verify_chapa_transaction(tx_ref)

    if verification_result['status'] == 'success' && verification_result['data']['status'] == 'success'
        # Payment was successful
        message = "Thank you, your payment was successful! Transaction ID: #{verification_result['data']['reference']}."
        bot.api.send_message(chat_id: chat_id, text: message)
    else
        # Payment failed or could not be verified
        message = "There was an issue with your payment. Please try again or contact support."
        bot.api.send_message(chat_id: chat_id, text: message)
    end
    end

    # Handling callback queries from inline keyboard
    def handle_callback_query(bot, callback_query)
        BotHelpers.validate_presence([bot, callback_query], %w[bot callback_query])
        user_id = callback_query.from.id
        puts "callback_query data is ------------- #{callback_query.data}"
        case callback_query.data
        when 'worldwide'
            send_worldwide_invoice(bot, callback_query)
        when 'ethiopia'
            handle_ethiopia_callback_query(bot, callback_query)
        when 'complete_payment'
          puts '------------- opening third party site to complete payment -------------'
          #  handle payment chapa verification here and internal
          #  ... callback with either payment_completed or payment_not_completed
        when 'payment_completed'
          #  handle payment successful
        when 'payment_not_completed'
          #  handle payment not successful
        else
            send_invalid_option_message(bot, callback_query)
        end
    end

    # Handling pre-checkout queries for payment validation
    def handle_precheckout_query(bot, pre_checkout_query)
      BotHelpers.validate_presence([bot, pre_checkout_query], %w[bot pre_checkout_query])
      process_precheckout(bot, pre_checkout_query, "worldwide")
    end

    # Handling shipping queries for product delivery
    def handle_shipping_query(bot, shipping_query)
      BotHelpers.validate_presence([bot, shipping_query], %w[bot shipping_query])
      provide_shipping_options(bot, shipping_query)
    end

    # Implementation for sending the start message
    def display_start_message(bot, message)
      start_message = "🇪🇹🇪🇹🇪🇹Hello, #{message.from.first_name}! Welcome to the Telegram Bot:)🇪🇹🇪🇹🇪🇹"
      bot.api.send_message(chat_id: message.chat.id, text: start_message)
    end

    # Implementation for generating a response based on the message command
    def message_response(command)
      responses = {
        '/help' => '🇪🇹🇪🇹🇪🇹You can use /start, /help, /bets, /top, /sport, /date, or /invoice for more options.🇪🇹🇪🇹🇪🇹',
        '/bets' => "You've chosen to view bets",
        '/top' => "You've chosen to view top bets",
        '/sport' => "You've chosen to view sports",
        '/date' => "You've chosen to view by date"
        # Add more commands and responses as needed
      }
      # Default response if the command is not recognized
      responses[command] || "I'm not sure how to respond to that. Try /help for a list of commands."
    end

    # Implementation for sending help or other info based on the command
    def send_helpful_message(bot, message)
      response = message_response(message.text)
      bot.api.send_message(chat_id: message.chat.id, text: response)
    end

    # Implementation for displaying invoice options
    def display_invoice_options(bot, message)
      options = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Worldwide', callback_data: 'worldwide'),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Ethiopia', callback_data: 'ethiopia')
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [options])
      bot.api.send_message(chat_id: message.chat.id, text: 'Select store location:', reply_markup: markup)
    end

    # Implementation for sending default response
    def send_default_message(bot, message)
      default_response = "🇪🇹🇪🇹🇪🇹You said: #{message.text}"
      bot.api.send_message(chat_id: message.chat.id, text: default_response)
    end

    # Implementation for sending a worldwide invoice
    def send_worldwide_invoice(bot, callback_query)
      invoice_details = InvoiceUtils.setup_worldwide_invoice_details
      InvoiceUtils.dispatch_invoice(bot, callback_query.message.chat.id, invoice_details)
    end

    #Implementation for sending an Ethiopia-specific invoice
    #def send_ethiopia_invoice(bot, callback_query)
      #invoice_details =  handle_ethiopia_precheckout_query(bot, callback_query)
      #dispatch_ethiopia_invoice(bot, callback_query.message.chat.id)
    #end

    #Assuming dispatch_ethiopia_invoice is missing or needs redefinition, here it is:
    #def dispatch_ethiopia_invoice(bot, chat_id)
    #Send the invoice to the specified chat ID using the provided invoice details
        #prices = [{ label: 'Product', amount: 5000 }] # Example price, adjust as needed
        #bot.api.send_invoice(
          #chat_id: chat_id,
          #title: 'Sample Product',
          #description: 'A sample product for demonstration purposes',
          #payload: 'unique_payload',
          #provider_token: ENV['PAYMENT_PROVIDER_CHAPA_TOKEN'], # Use CHAPA token from .env
          #start_parameter: 'sample-product',
          #currency: 'USD',
          #prices: prices,
          #need_name: true,
          #need_shipping_address: true,
          #is_flexible: true
        #)
    #end

    # Implementation for handling invalid option selection
    def send_invalid_option_message(bot, callback_query)
      invalid_option_text = 'Invalid option selected.'
      bot.api.send_message(chat_id: callback_query.from.id, text: invalid_option_text)
    end

   def process_precheckout(bot, pre_checkout_query, user_preference)
    unless user_preference == 'worldwide'
        # Generate "Complete Payment" inline button in the chat screen
        generate_payment_button(bot, pre_checkout_query.from.id)
        handle_chapa_callback(bot, chat_id, tx_ref)
        # Note: The actual payment verification and completion should be handled separately,
        # typically via a callback once the user completes the payment process on Chapa's end.
        # You need to have a separate handler for Chapa's callback to your system,
        # which should update some state to indicate that the user has completed the payment.

        # This is just a placeholder for where you would handle the state update.
        # You would likely do this in response to a webhook or some other callback from Chapa.
        # For the purposes of this example, we're just immediately proceeding to the next step,
        # but in a real application, this should only happen after verification is complete.

        # Assuming you have a method to check if the payment was completed:
        # if payment_completed(pre_checkout_query.from.id)
        #   bot.api.answer_pre_checkout_query(pre_checkout_query_id: pre_checkout_query.id, ok: true)
        # end

        # The above 'if' check should be triggered by some sort of notification
        # that the payment has been completed, which is likely outside the scope
        # of this particular method and handled elsewhere in your bot's workflow.
    else
        # If user preference is 'worldwide', directly approve the pre-checkout.
        bot.api.answer_pre_checkout_query(pre_checkout_query_id: pre_checkout_query.id, ok: true)
    end
    end

    def generate_payment_button(bot, chat_id)
    keyboard = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Complete Payment', callback_data: 'complete_payment')
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [keyboard])
    bot.api.send_message(chat_id: chat_id, text: "Please complete your payment using the button below.", reply_markup: markup)
    end

    # Placeholder for payment completion check - you'll need to implement this based on your own logic
    def payment_completed(user_id)
    # Check if payment has been completed for the user
    # This could involve checking a database or some other state that is updated
    # when the payment completion callback is received from Chapa.
    return false # Change this to reflect the actual payment status
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

    # Remember to implement all the helper methods needed for the logic above.
  end
end

MyTelegramBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
