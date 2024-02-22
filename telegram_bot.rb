# frozen_string_literal: true

# telegram_bot.rb

require 'telegram/bot'
require 'dotenv/load'
require 'byebug'
require 'httparty'
require 'logger'
require 'open-uri'
require 'nokogiri'

class MyTelegramBot
  class << self

    @is_worldwide = false
    def respond_to_message(bot, message)
      begin
        # Check if bot and message are valid
        raise ArgumentError, "Invalid bot or message" if bot.nil? || message.nil?

        case message.text
        when '/start'
          send_message(bot, message.chat.id, "🇪🇹🇪🇹🇪🇹Hello, #{message.from.first_name}! Welcome to the Telegram Bot:)🇪🇹🇪🇹🇪🇹")
        when '/help'
          send_message(bot, message.chat.id, '🇪🇹🇪🇹🇪🇹You can use /start, /help, /bets, /top, /sport, /date, or /invoice for more options.🇪🇹🇪🇹🇪🇹')
        when '/bets'
          send_message(bot, message.chat.id, "You've chosen to view bets by bets")
        when '/top'
          send_message(bot, message.chat.id, "You've chosen to view bets by topbets")
        when '/sport'
          send_message(bot, message.chat.id, "You've chosen to view bets by sport")
        when '/date'
          send_message(bot, message.chat.id, "You've chosen to view bets by date")
        when '/invoice'
             options = [
          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Worldwide', callback_data: 'worldwide'),
          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Ethiopia', callback_data: 'ethiopia')
        ]
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [options])
        bot.api.send_message(chat_id: message.chat.id, text: "Select store location:", reply_markup: markup)
        else
          send_message(bot, message.chat.id, "🇪🇹🇪🇹🇪🇹You said: #{message.text}")
        end
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end
    
    def handle_callback_query(bot, callback_query)
      case callback_query.data
      when 'worldwide'
        @is_worldwide = true
        send_worldwide_invoice(bot, callback_query)
      when 'ethiopia'
        send_ethiopia_invoice(bot, callback_query)
      else
        bot.api.send_message(chat_id: callback_query.from.id, text: "Invalid option.")
      end
    end

   def send_ethiopia_invoice(bot, callback_query)
      begin
        # Check if bot and chat_id are valid
        raise ArgumentError, "Invalid bot or chat_id" if bot.nil? || callback_query.nil?

        prices = [{ label: 'Product', amount: 5000 }] # Example price, adjust as needed
        bot.api.send_invoice(
          chat_id: callback_query.message.chat.id,
          title: 'Sample Product',
          description: 'A sample product for demonstration purposes',
          payload: 'unique_payload',
          provider_token: ENV['PAYMENT_PROVIDER_CHAPA_TOKEN'], # Use Chapa/ Stripe token from .env
          start_parameter: 'sample-product',
          currency: 'USD',
          prices: prices,
          need_name: true,
          need_shipping_address: true,
          need_email: true,
          need_phone_number: true,
          is_flexible: true
        )
        puts '[Logger SLabs] -------------- invoice sent.'
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end
    
    def send_worldwide_invoice(bot, callback_query)
      begin
        # Check if bot and chat_id are valid
        raise ArgumentError, "Invalid bot or chat_id" if bot.nil? || callback_query.nil?

       prices = [{ label: 'Product', amount: 5000 }] # Example price, adjust as needed
        bot.api.send_invoice(
          chat_id: callback_query.message.chat.id,
          title: 'Sample Product',
          description: 'A sample product for demonstration purposes',
          payload: 'unique_payload',
          provider_token: ENV['PAYMENT_PROVIDER_STRIPE_TOKEN'], # Use Chapa/ Stripe token from .env
          start_parameter: 'sample-product',
          currency: 'USD',
          prices: prices,
          need_name: true,
          need_shipping_address: true,
          is_flexible: true
        )
        puts '[Logger SLabs] -------------- invoice sent.'
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end

    def send_message(bot, chat_id, text)
      begin
        # Check if bot, chat_id, and text are valid
        raise ArgumentError, "Invalid bot, chat_id, or text" if bot.nil? || chat_id.nil? || text.nil?

        bot.api.send_message(chat_id: chat_id, text: text)
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end


     def run(token)
      begin
        # Check if token is valid
        raise ArgumentError, "Invalid token" if token.nil? || token.empty?

        Telegram::Bot::Client.run(token) do |bot|
          bot.listen do |update|
            case update
            when Telegram::Bot::Types::Message
              puts "Responding to MESSAGE...."
              respond_to_message(bot, update)
            when Telegram::Bot::Types::PreCheckoutQuery
              puts "Handling PRECHECKOUT query...."
            bot.api.answer_pre_checkout_query(pre_checkout_query_id: update.id, ok: true) if @is_worldwide          
            handle_ethiopia_precheckout_query(bot, update) if !@is_worldwide
            when Telegram::Bot::Types::ShippingQuery
              puts "Handling SHIPPING query...."
              handle_shipping_query(bot, update)
            when Telegram::Bot::Types::CallbackQuery
              puts "Handling CALLBACK query...."
              handle_callback_query(bot,update)
            end
          end
        end
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end

    def handle_ethiopia_precheckout_query(bot, pre_checkout_query)
    begin
        # Check if bot and pre_checkout_query are valid
        raise ArgumentError, "Invalid bot or pre_checkout_query" if bot.nil? || pre_checkout_query.nil?
        # Extract necessary details from the invoice
        from = pre_checkout_query.from
        order_info = pre_checkout_query.order_info
        title = order_info.name
        email = order_info.email
        first_name = from.first_name
        last_name = from.last_name
        phone_number = order_info.phone_number
        currency = pre_checkout_query.currency
        amount = pre_checkout_query.total_amount
        tx_ref = generate_tx_ref # random tx_ref 
       
        # Load Chapa secret key from .env
        chapa_secretkey = ENV['PAYMENT_PROVIDER_CHAPA_SECRET']

        # Create the payload hash
        payload = {
        amount: amount,
        currency: currency,
        email: email,
        first_name: first_name,
        last_name: last_name,
        phone_number: phone_number,
        tx_ref: tx_ref,
        chapa_secretkey: chapa_secretkey,
        return_url: "https://t.me/chatID_retreiver_bot"
        }
        
        # Display the payload
        puts "[SLabs] Payload: #{payload}"

        # Check if all mandatory fields are present
        mandatory_fields = [:chapa_secretkey, :amount, :phone_number, :tx_ref]
        if mandatory_fields.all? { |field| payload.key?(field) }
              
        # Send the POST request to Chapa API to initialize the transaction
      response = HTTParty.post(
        'https://api.chapa.co/v1/transaction/initialize',
        headers: {
          'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}",
          'Content-Type' => 'application/json'
        },
        body: payload.to_json
      )
      # Check the response and handle accordingly
      if response.code == 200
        # Transaction initialized successfully
        checkout_url = JSON.parse(response.body)['data']['checkout_url']
        puts "[SLabs] checkout url obtained ... #{checkout_url}"
        # If all required information is collected, proceed with the pre-checkout query
        puts '[Logger - SLabs] about to display payment options'
        #display_payment_options(bot, pre_checkout_query.from.id, checkout_url)
        
        # Cancel here and return to chat
        bot.api.answer_pre_checkout_query(pre_checkout_query_id: pre_checkout_query.id, ok: true)
      else
        # Handle error response from Chapa API
        puts "Error: #{response.body}"
        # Handle or log the error accordingly
      end
        else
        puts "missing mandatory fields...."
        # Handle missing mandatory fields in the payload
        #handle_missing_fields(bot, pre_checkout_query.from.id, mandatory_fields)
        end
    rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Handle errors accordingly
    rescue StandardError => e
        puts "Error: #{e.message}"
        # Handle errors accordingly
    end
    end
    
    
    def display_payment_options(bot, pre_checkout_query_id, checkout_url)
        begin
            # Check if bot and pre_checkout_query_id are valid
            raise ArgumentError, "Invalid bot or pre_checkout_query_id" if bot.nil? || pre_checkout_query_id.nil?

            message_text = "Please complete your payment by selecting one of the available payment methods at the following link: #{checkout_url}"
            # Correcting the inline keyboard structure
            keyboard = [
                [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Complete Payment', url: checkout_url)]
            ]
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

            # Sending the message with the corrected keyboard
            bot.api.send_message(chat_id: pre_checkout_query_id, text: message_text, reply_markup: markup)
        rescue ArgumentError => e
            puts "Error: #{e.message}"
            # Log or handle the error accordingly
        rescue StandardError => e
            puts "Error: #{e.message}"
            # Log or handle the error accordingly
        end
    end
    
    def generate_tx_ref(prefix = 'chewatatest-')
      # Generate a random number between 1000 and 9999
      random_number = rand(1000..9999)
      # Concatenate the prefix with the random number
      "#{prefix}#{random_number}"
    end
    
     def handle_shipping_query(bot, shipping_query)
      begin
        # Check if bot and shipping_query are valid
        raise ArgumentError, "Invalid bot or shipping_query" if bot.nil? || shipping_query.nil?
        shipping_options = [
          Telegram::Bot::Types::ShippingOption.new(
            id: 'standard',
            title: 'Standard Shipping',
            prices: [Telegram::Bot::Types::LabeledPrice.new(label: 'Standard', amount: 1000)]  # Example: $10.00
          ),
          Telegram::Bot::Types::ShippingOption.new(
            id: 'express',
            title: 'Express Shipping',
            prices: [Telegram::Bot::Types::LabeledPrice.new(label: 'Express', amount: 2000)]  # Example: $20.00
          )
        ]
        bot.api.answer_shipping_query(
          shipping_query_id: shipping_query.id,
          ok: true,
          shipping_options: shipping_options
        )
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      rescue StandardError => e
        puts "Error: #{e.message}"
        # Log or handle the error accordingly
      end
    end

  end
end

MyTelegramBot.run(ENV['TELEGRAM_BOT_TOKEN']) if __FILE__ == $PROGRAM_NAME
