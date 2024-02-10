# frozen_string_literal: true

# spec/telegram_bot_spec.rb
require_relative '../telegram_bot'

RSpec.describe MyTelegramBot do
  describe '.respond_to_message' do
    let(:fake_api) { double('Telegram::Bot::Api') }
    let(:bot) { double('Telegram::Bot::Client', api: fake_api) }
    let(:message) do
      double('Telegram::Bot::Types::Message', text: message_text, chat: double('Telegram::Bot::Types::Chat', id: 123),
                                              from: double('Telegram::Bot::Types::User', first_name: 'John'))
    end

    context 'when the message is /start' do
      let(:message_text) { '/start' }

      it 'sends a welcome message' do
        expect(fake_api).to receive(:send_message).with(hash_including(chat_id: 123,
                                                                       text: '🇪🇹🇪🇹🇪🇹Hello, John! Welcome to the Telegram Bot:)🇪🇹🇪🇹🇪🇹'))
        MyTelegramBot.respond_to_message(bot, message)
      end
    end

    context 'when the message is /help' do
      let(:message_text) { '/help' }

      it 'sends a help message' do
        expect(fake_api).to receive(:send_message).with(hash_including(chat_id: 123,
                                                                       text: '🇪🇹🇪🇹🇪🇹You can use /start, /help, /bets, /top, /sport, /date for more options.🇪🇹🇪🇹🇪🇹'))
        MyTelegramBot.respond_to_message(bot, message)
      end
    end

    context 'when the message is unrecognized' do
      let(:message_text) { 'unrecognized' }

      it 'sends a default echo message' do
        expect(fake_api).to receive(:send_message).with(hash_including(chat_id: 123,
                                                                       text: '🇪🇹🇪🇹🇪🇹You said: unrecognized'))
        MyTelegramBot.respond_to_message(bot, message)
      end
    end

    context 'when the message is /bets' do
      let(:message_text) { '/bets' }
      it 'responds with the bets view message' do
        expect(fake_api).to receive(:send_message).with(chat_id: 123, text: "You've chosen to view bets by bets")
        described_class.respond_to_message(bot, message)
      end
    end

    context 'when the message is /top' do
      let(:message_text) { '/top' }
      it 'responds with the topbets view message' do
        expect(fake_api).to receive(:send_message).with(chat_id: 123, text: "You've chosen to view bets by topbets")
        described_class.respond_to_message(bot, message)
      end
    end

    context 'when the message is /sport' do
      let(:message_text) { '/sport' }
      it 'responds with the sport view message' do
        expect(fake_api).to receive(:send_message).with(chat_id: 123, text: "You've chosen to view bets by sport")
        described_class.respond_to_message(bot, message)
      end
    end

    context 'when the message is /date' do
      let(:message_text) { '/date' }
      it 'responds with the date view message' do
        expect(fake_api).to receive(:send_message).with(chat_id: 123, text: "You've chosen to view bets by date")
        described_class.respond_to_message(bot, message)
      end
    end
  end
end
