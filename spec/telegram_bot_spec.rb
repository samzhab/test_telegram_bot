# frozen_string_literal: true

require_relative '../telegram_bot'
require 'webmock/rspec'
require 'vcr'
require 'telegram/bot'
require 'logger'

RSpec.describe MyTelegramBot do
  let(:token) { 'dummy_token' }
  let(:chat_id) { 123 }
  let(:user_id) { 1 }
  let(:mock_telegram_bot_api) { instance_double('Telegram::Bot::Api') }
  let(:mock_bot) { instance_double('Telegram::Bot::Client', api: mock_telegram_bot_api) }

  # Common setup for all tests
  before do
    allow(Telegram::Bot::Client).to receive(:run).and_yield(mock_bot)
    allow(Telegram::Bot::Api).to receive(:new).with(token).and_return(mock_telegram_bot_api)
    allow(mock_telegram_bot_api).to receive(:send_message)
    allow(mock_telegram_bot_api).to receive_messages(
      send_message: nil,
      send_invoice: nil,
      answer_pre_checkout_query: nil,
      answer_shipping_query: nil,
      answer_callback_query: nil
    )
  end

  describe '.run' do
    it 'initializes and listens for messages' do
      expect(mock_bot).to receive(:listen)
      MyTelegramBot.run(token)
      expect(Telegram::Bot::Client).to have_received(:run).with(token)
    end
  end

  describe '#bot_listen' do
    commands = ['/help', '/sports_betting', '/promotion', '/events', '/scheduler', '/payments']
    let(:message) do
      instance_double('Telegram::Bot::Types::Message',
                      text: message_text,
                      chat: instance_double('Telegram::Bot::Types::Chat', id: chat_id),
                      from: instance_double('Telegram::Bot::Types::User', id: user_id, first_name: 'John'))
    end

    commands.each do |command|
      context "when receiving a #{command} message" do
        let(:message_text) { command }
        it "responds to #{command}" do
          # Simulate the incoming message being processed
          allow(mock_bot).to receive(:listen).and_yield(message)
          expect(mock_telegram_bot_api).to receive(:send_message).with(hash_including(chat_id: chat_id))

          MyTelegramBot.new.bot_listen(mock_bot)
        end
      end
    end
  end

  describe 'BotHelpers' do
    context 'validate_presence' do
      it 'raises ArgumentError if values are missing' do
        expect { BotHelpers.validate_presence([nil], ['token']) }.to raise_error(ArgumentError)
      end

      it 'does not raise error if values are present' do
        expect { BotHelpers.validate_presence(['value'], ['name']) }.not_to raise_error
      end
    end
  end

  describe 'InvoiceUtils' do
    let(:invoice_details) do
      {
        title: 'Test Invoice',
        description: 'This is a test invoice',
        start_parameter: 'test_start',
        currency: 'USD',
        prices: [{ label: 'Test', amount: 1234 }]
      }
    end

    context 'setup_worldwide_invoice_details' do
      it 'loads invoice details from YAML file' do
        expect(InvoiceUtils.setup_worldwide_invoice_details).not_to be_empty
      end
    end

    context 'dispatch_invoice' do
      it 'calls send_invoice on mock_bot mock_telegram_bot_api' do
        expect(mock_telegram_bot_api).to receive(:send_invoice).with(chat_id: chat_id, **invoice_details)
        InvoiceUtils.dispatch_invoice(mock_bot, chat_id, invoice_details)
      end
    end
  end

  describe 'ErrorHandler' do
    context 'handle_error' do
      it 'logs the error' do
        expect { ErrorHandler.handle_error(StandardError.new('test error'), 'TestContext') }
          .to output(/TestContext: test error/).to_stdout
      end
    end
  end
end
