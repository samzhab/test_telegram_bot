
require 'sinatra'
require 'httparty'
require 'byebug'
require 'telegram/bot'
require 'dotenv/load'

require 'logger'

get '/' do
  # Extract chat_id from query parameters
  chat_id = params['chat_id']
  # Display the chat_id
  "Received chat_id: #{chat_id}"
end

get '/chapa_payment_verification' do
  # Extract transaction reference from query parameters
  tx_ref = params['tx_ref']
  chat_id = params['chat_id']
  puts params
  # Call your method to verify the payment with Chapa
  verification_result = verify_chapa_transaction(tx_ref)

  if verification_result.nil?
    message = "በድጋሚ ይሞክሩት። ወይም የደንበኛ ረዳቶቻችንን ያናግሩ። There was a problem with your payment. Please try again or contact support."
    send_telegram_message(chat_id, message)
    "There was a problem with your payment."
  elsif verification_result.is_a?(Hash) && verification_result.key?('status') && verification_result['status'] == 'success' && verification_result['data'].is_a?(Hash) && verification_result['data'].key?('status') && verification_result['data']['status'] == 'success'
    message = "ክፍያዎን በሚገባ ጨርሰዋል። ለግብይቶ እናመሰግናለን። Your payment was successful! Thank you for your purchase."
    send_telegram_message(chat_id, message)
    "Payment processed."
  else
      message = "በድጋሚ ይሞክሩት። ወይም የደንበኛ ረዳቶቻችንን ያናግሩ። There was a problem with your payment. Please try again or contact support."
      send_telegram_message(chat_id, message)
      "There was a problem with your payment."
  end
end

def verify_chapa_transaction(tx_ref)
  response = HTTParty.get(
    "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/#{tx_ref}",
    headers: { "Authorization" => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" }
  )
  # Check if response is successful and contains expected keys
  if response.success?
  # Parse the response body as JSON
  begin
    parsed_response = JSON.parse(response.body)
  rescue JSON::ParserError => e
    # If parsing fails, handle the error (e.g., log it) and return nil
    puts "Failed to parse response body as JSON: #{e.message}"
    nil
  end

  return parsed_response
else
  puts "Failed to verify transaction with Chapa: #{response.code} - #{response.body}"
  nil
end
end

def send_telegram_message(chat_id, message)
  HTTParty.post("https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage",
                body: {
                  chat_id: chat_id,
                  text: message
                })
end
