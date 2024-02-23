require_relative '../verify_chapa' # Adjust the path as necessary
require 'rspec'
require 'rack/test'
require 'vcr'
require 'webmock/rspec' # Make sure WebMock is required
require 'json'

ENV['RACK_ENV'] = 'test'

describe 'VerifyChapa' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    # Mock the response from Telegram API to ensure it doesn't actually send messages during tests
    stub_request(:post, /https:\/\/api.telegram.org\/bot.*/).to_return(status: 200, body: '{"ok":true,"result":{}}', headers: {})

    # Mock the Chapa payment verification response for a successful payment
    stub_request(:get, "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/123")
      .with(headers: {'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}"})
      .to_return(status: 200, body: '{"status":"success", "data":{"status":"success"}}', headers: {})

    # Mock the Chapa payment verification response for a failed payment
    stub_request(:get, "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/fail_ref")
      .with(headers: {'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}"})
      .to_return(status: 200, body: '{"status":"fail", "data":{"status":"fail"}}', headers: {})
  end

  describe 'GET /chapa_payment_verification' do
    context 'when payment is successful' do
      it 'sends success message to Telegram' do
        get '/chapa_payment_verification', tx_ref: '123', chat_id: '456'
        # puts "Response: #{last_response.body}"
        expect(last_response).to be_ok
        expect(last_response.body).to include('Payment processed')
      end
    end

    context 'when payment fails' do
      it 'sends failure message to Telegram' do
        get '/chapa_payment_verification', tx_ref: 'fail_ref', chat_id: '789'
        puts "Response: #{last_response.body}"
        expect(last_response).to be_ok
        expect(last_response.body).to include('There was a problem with your payment.')
      end
    end

    context 'when payment fails with nil' do
      it 'sends failure message to Telegram' do
        get '/chapa_payment_verification'
        puts "Response: #{last_response.body}"
        expect(last_response).to be_ok
        expect(last_response.body).to include('There was a problem with your payment.')
      end
    end
  end
end
