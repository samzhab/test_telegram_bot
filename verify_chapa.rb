require 'sinatra'
require 'httparty'
require 'byebug'
require 'telegram/bot'
require 'dotenv/load'
require 'logger'
require 'yaml'

# Load environment variables from .env file
Dotenv.load

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

# Load UI strings from YAML file
UI_STRINGS = YAML.load_file('ui_strings.yml')

TELEGRAM_BOT_TOKEN = ENV['TELEGRAM_BOT_TOKEN']

get '/' do
  # Extract chat_id from query parameters
  chat_id = params['chat_id']
  # Display the chat_id
  "Recieved chat_id: #{chat_id}"
end

# post "/webhook/#{ENV['TELEGRAM_BOT_TOKEN']}" do
#   request.body.rewind
#   data = JSON.parse(request.body.read)
#
#   # Check if the update is a message
#   if data['message']
#     message = data['message']
#     chat_id = message['chat']['id']
#     text = message['text']
#
#     # Echo back the received message
#     response = HTTParty.post(
#       "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage",
#       body: {
#         chat_id: chat_id,
#         text: text
#       },
#       headers: {
#         'Content-Type' => 'application/json'
#       }
#     )
#
#     puts response.body if response.code != 200
#   end
#
#   status 200
# end
#
# # Set the webhook
# post '/webhook/set_webhook' do
#   response = HTTParty.post(
#     "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/setWebhook",
#     body: {
#       url: "#{ENV['CALLBACK_URL']}/#{ENV['TELEGRAM_BOT_TOKEN']}"
#     },
#     headers: {
#       'Content-Type' => 'application/json'
#     }
#   )
#
#   if response.code == 200
#     'Webhook set successfully!'
#   else
#     'Failed to set webhook!'
#   end
# end
#
# # Remove the webhook
# post '/webhook/remove_webhook' do
#   response = HTTParty.post(
#     "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/deleteWebhook"
#   )
#
#   if response.code == 200
#     'Webhook removed successfully!'
#   else
#     'Failed to remove webhook!'
#   end
# end
#
get '/dir' do
  send_file 'lib/webapps/dir/index.html'
end

get '/styles.css' do
  send_file 'lib/webapps/dir/styles.css'
end

get '/script.js' do
  send_file 'lib/webapps/dir/script.js'
end

get '/businesses.json' do
  send_file 'lib/webapps/dir/businesses.json'
end

# Serve files for '/bets' route
get '/bets' do
  send_file 'lib/webapps/bets/index.html'
end

get '/styles.css' do
  send_file 'lib/webapps/bets/styles.css'
end

get '/script.js' do
  send_file 'lib/webapps/bets/script.js'
end

get '/coredata.json' do
  send_file 'lib/webapps/bets/coredata.json'
end

get '/matches.json' do
  send_file 'lib/webapps/bets/matches.json'
end

get '/chapa_payment_verification' do
  # Extract transaction reference from query parameters
  tx_ref = params['tx_ref']
  chat_id = params['chat_id']
  LOGGER.info("Received Chapa payment verification request: #{params}")

  # Call your method to verify the payment with Chapa
  verification_result = verify_chapa_transaction(tx_ref)
  if verification_result.nil?
    message = UI_STRINGS['chapa_payment_error']
    send_telegram_message(chat_id, message)
    LOGGER.error("Payment verification failed: No result returned for tx_ref #{tx_ref}")
    "There was a problem with your payment."
  elsif verification_result.is_a?(Hash) && verification_result.key?('status') && verification_result['status'] == 'success' && verification_result['data'].is_a?(Hash) && verification_result['data'].key?('status') && verification_result['data']['status'] == 'success'
    message = UI_STRINGS['chapa_payment_success']
    send_telegram_message(chat_id, message)
    LOGGER.info("Payment verification successful for tx_ref #{tx_ref}")
    "Payment processed."
  else
    message = UI_STRINGS['chapa_payment_error']
    send_telegram_message(chat_id, message)
    LOGGER.error("Payment verification failed with status: #{verification_result['status'] if verification_result.is_a?(Hash)} for tx_ref #{tx_ref}")
    "There was a problem with your payment."
  end
end

def verify_chapa_transaction(tx_ref)
  LOGGER.info("Verifying Chapa transaction with tx_ref: #{tx_ref}")
  response = HTTParty.get(
    "#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/#{tx_ref}",
    headers: { "Authorization" => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" }
  )
  # Check if response is successful and contains expected keys
  if response.success?
    # Parse the response body as JSON
    begin
      parsed_response = JSON.parse(response.body)
      LOGGER.info("Successfully verified transaction with Chapa: #{parsed_response}")
      parsed_response
    rescue JSON::ParserError => e
      # If parsing fails, log the error and return nil
      LOGGER.error("Failed to parse response body as JSON: #{e.message}")
      nil
    end
  else
    LOGGER.error("Failed to verify transaction with Chapa: #{response.code} - #{response.body}")
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
