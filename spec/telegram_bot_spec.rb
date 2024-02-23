# frozen_string_literal: true

require_relative '../telegram_bot'
require 'webmock/rspec'
require 'vcr'
require 'telegram/bot'

RSpec.describe MyTelegramBot do
  let(:token) { 'dummy_token' }
  let(:api) { double('Telegram::Bot::Api') }
  let(:bot) { instance_double('Telegram::Bot::Client', api: api) }
  let(:chat_id) { 123 }
  let(:user_id) { 1 }
  let(:message_text) { '/start' }
  let(:message) do
    instance_double('Telegram::Bot::Types::Message',
                    text: message_text,
                    chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id),
                    from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John'))
  end
  let(:callback_query) do
    instance_double('Telegram::Bot::Types::CallbackQuery',
                    from: message.from,
                    message: message,
                    data: 'worldwide')
  end
  let(:precheckout_query) do
  instance_double('Telegram::Bot::Types::PreCheckoutQuery',
                  from: message.from,
                  id: 'precheckout_query_id',
                  invoice_payload: 'invoice_payload',
                  currency: 'USD',
                  total_amount: 1000) # Adjust attributes as needed
  end

  let(:shipping_query) do
    instance_double('Telegram::Bot::Types::ShippingQuery',
                    from: message.from,
                    id: 'shipping_query_id',
                    invoice_payload: 'invoice_payload',
                    shipping_address: instance_double('Telegram::Bot::Types::ShippingAddress', country_code: 'US', state: 'State', city: 'City', street_line1: 'Line 1', street_line2: 'Line 2', post_code: 'Post Code')) # Adjust attributes as needed
  end

  before do
    allow(Telegram::Bot::Client).to receive(:run).and_yield(bot)
    allow(bot).to receive(:listen).and_yield(message)
    allow(bot).to receive(:api).and_return(api)
    allow(api).to receive(:send_message)
    allow(api).to receive(:send_invoice)
    allow(api).to receive(:answer_pre_checkout_query)
    allow(api).to receive(:answer_shipping_query)
    allow(api).to receive(:answer_callback_query)
    allow(bot).to receive(:listen).and_yield(message).and_yield(callback_query).and_yield(precheckout_query).and_yield(shipping_query)
  end

  describe '.run' do
    it 'initializes and listens for messages' do
      expect(bot).to receive(:listen)
      MyTelegramBot.run(token)  # Changed from Telegram::Bot::Client.run to MyTelegramBot.run
      expect(Telegram::Bot::Client).to have_received(:run).with(token)
    end
  end

  describe '#run' do

    context 'when receiving a message' do

      # Test for '/start' command
      it "sends a welcome message in response to '/start'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/start', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "🇪🇹🇪🇹🇪🇹Hello, John! Welcome to the Telegram Bot:)🇪🇹🇪🇹🇪🇹"))
      end

      # Test for '/help' command
      it "provides help information in response to '/help'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/help', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "🇪🇹🇪🇹🇪🇹You can use /start, /help, /bets, /top, /sport, /date, or /invoice for more options.🇪🇹🇪🇹🇪🇹"))
      end

      # Test for '/bets' command
      it "responds to '/bets'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/bets', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "You've chosen to view bets"))
      end

      # Test for '/top' command
      it "responds to '/top'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/top', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "You've chosen to view top bets"))
      end

      # Test for '/sport' command
      it "responds to '/sport'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/sport', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "You've chosen to view sports"))
      end

      # Test for '/date' command
      it "responds to '/date'" do
        described_class.respond_to_message(bot, instance_double('Telegram::Bot::Types::Message', text: '/date', chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id), from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')))
        expect(api).to have_received(:send_message).with(hash_including(text: "You've chosen to view by date"))
      end

      # Test for '/invoice' command

      it "responds to '/invoice' with invoice options" do
      described_class.respond_to_message(
        bot,
        instance_double(
          'Telegram::Bot::Types::Message',
          text: "/invoice",
          chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id),
          from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')
        )
      )

      expect(api).to have_received(:send_message).with(
        hash_including(
          chat_id: chat_id,
          text: 'Select store location:'
        )
      )
      end
    end

    context 'when sending an inline keyboard' do
      it 'sends a message with an inline keyboard' do
        described_class.respond_to_message(
          bot,
          instance_double(
            'Telegram::Bot::Types::Message',
            text: "/invoice",
            chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id),
            from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John')
          )
        )

          expect(api).to have_received(:send_message).with(hash_including(text: 'Select store location:', reply_markup: instance_of(Telegram::Bot::Types::InlineKeyboardMarkup)))
        end
    end

  #   context 'when receiving a callback query' do
  #     it 'handles the worldwide callback query' do
  #       expect(api).to have_received(:answer_callback_query).with(hash_including(callback_query_id: callback_query.from.id.to_s))
  #     end
  #   end
  #   context 'when receiving a precheckout query' do
  #   it 'handles the precheckout query' do
  #     expect(api).to have_received(:answer_pre_checkout_query).with(hash_including(pre_checkout_query_id: precheckout_query.id))
  #   end
  # end
  #
  # context 'when receiving a shipping query' do
  #   it 'handles the shipping query' do
  #     expect(api).to have_received(:answer_shipping_query).with(hash_including(shipping_query_id: shipping_query.id))
  #   end
  # end
  end

#
#
#   describe 'handling callback queries' do
#   before { allow(bot).to receive(:listen).and_yield(callback_query) }
#
#   shared_examples 'a callback query handler' do |data, expect_invoice|
#     let(:callback_query_data) { data }
#
#     it "handles #{data} callback queries" do
#       VCR.use_cassette("telegram_bot_#{data}_callback_query") do
#         described_class.run(token)
#         expect(api).to have_received(:answer_callback_query).with(hash_including(callback_query_id: callback_query.from.id.to_s))
#
#         if expect_invoice
#           expect(api).to have_received(:send_invoice).with(hash_including(chat_id: chat_id))
#         else
#           expect(api).not_to have_received(:send_invoice)
#         end
#       end
#     end
#   end
#
#   include_examples 'a callback query handler', 'ethiopia', true
#   include_examples 'a callback query handler', 'worldwide', true
#   include_examples 'a callback query handler', 'invalid', false
# end

#
#   describe 'handling shipping queries' do
#     let(:shipping_query) { instance_double('Telegram::Bot::Types::ShippingQuery', id: 'shipping-query-id', shipping_address: instance_double('Telegram::Bot::Types::ShippingAddress')) }
#
#     it 'provides shipping options when valid' do
#       VCR.use_cassette('telegram_bot_shipping_options') do
#         MyTelegramBot.provide_shipping_options(bot, shipping_query)
#         expect(api).to have_received(:answer_shipping_query).with(hash_including(shipping_query_id: 'shipping-query-id', ok: true))
#       end
#     end
#
#     context 'with invalid conditions' do
#       before do
#         allow(shipping_query).to receive(:shipping_address).and_return(nil) # Simulate invalid conditions
#       end
#
#       it 'responds with error when address is invalid' do
#         VCR.use_cassette('telegram_bot_invalid_shipping_address') do
#           MyTelegramBot.provide_shipping_options(bot, shipping_query)
#           expect(api).to have_received(:answer_shipping_query).with(hash_including(shipping_query_id: 'shipping-query-id', ok: false))
#         end
#       end
#     end
#   end

  # Add other contexts and describe blocks as needed for full coverage
end
