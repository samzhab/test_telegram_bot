
# Advanced Telegram Bot Deployment and Integration Guide

This comprehensive guide provides detailed instructions for deploying a Telegram bot with enhanced functionalities, including Chapa payment integration and callback handling via a Sinatra web server, on an Amazon EC2 instance. This document serves as an essential resource for developers aiming to leverage advanced features and integrations in their Telegram bot projects.


- A Telegram bot token obtained via [@BotFather](https://t.me/botfather).
- An EC2 instance with Ubuntu and Ruby installed.
- The `telegram-bot-ruby` gem for interacting with the Telegram Bot API.

## Step 1: Bot Script Preparation

Ensure your Telegram bot script (`telegram_bot.rb`) is ready and tested. The script should include a polling loop or webhook setup for receiving updates.

## Step 2: Wrapper Script Creation

Create a wrapper script (`start_bot.sh`) to handle the environment setup, including loading RVM and specifying the Ruby version:

```bash
#!/bin/bash
source /home/admin/.rvm/scripts/rvm
rvm use 3.1.2
exec ruby /home/admin/test_telegram_bot/telegram_bot.rb
```

Make sure to replace paths and Ruby version as necessary.

## Step 3: Systemd Service File

Create a systemd service file (`/etc/systemd/system/test_telegram_bot.service`) with the following content:

```ini
[Unit]
Description=Telegram Bot
After=network.target

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin/test_telegram_bot
ExecStart=/home/admin/test_telegram_bot/start_bot.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

## Step 4: Enabling and Starting the Service

Reload systemd, enable, and start your bot service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable test_telegram_bot.service
sudo systemctl start test_telegram_bot.service
```

## Step 5: Monitoring and Logs

Check the status of your service and review logs as needed:

```bash
sudo systemctl status test_telegram_bot.service
journalctl -u test_telegram_bot.service
```

## Integrating Redis

Our project now leverages Redis for enhanced data handling and caching capabilities, essential for optimizing performance and scalability.

### Setting Up Redis

#### Installation

Ensure Redis is installed on your development and production environments. Local development can typically use package managers like `brew` for macOS or `apt` for Ubuntu.

#### Configuration

Secure your Redis instance. Set a strong password and adjust settings for your needs in `redis.conf`, especially for production environments.

### Environment Configuration

Include Redis configuration in your `.env` file:

```makefile
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=your_secure_password
```

### Populating Dummy Data with Rake Task

Use the provided rake task to initialize Redis with dummy data crucial for development and testing:

```shell
rake redis:init
```

This task ensures your environment mirrors production-like data, facilitating accurate testing and development.

### Chapa Payment Integration

Integrate Chapa for payment processing in your application as follows:

1. Obtain your Chapa credentials (API key, secret, etc.) and set them as environment variables in your `.env` file:

   ```
   PAYMENT_PROVIDER_CHAPA_SECRET=your_chapa_secret
   PAYMENT_PROVIDER_CHAPA_VERIFY=your_chapa_verification_endpoint
   ```

2. In your payment processing script, implement the payment verification logic using HTTParty to make a GET request to Chapa's verification URL:

   ```ruby
   require 'httparty'

   def verify_chapa_transaction(tx_ref)
     response = HTTParty.get("#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/#{tx_ref}",
                             headers: { 'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" })
     if response.success?
       response.parsed_response  # Return the parsed JSON response
     else
       nil  # Handle errors or failed requests
     end
   end
   ```

3. Use the verification method in your route handlers to check the status of transactions and respond appropriately.


Add details about integrating Chapa for payment processing, setting up the account, configuring environment variables, and handling payment verifications.


### Sinatra Web Server Setup

To set up a Sinatra web server to handle callbacks, follow these steps:

1. Install the required gems by adding them to your `Gemfile` and running `bundle install`:

   ```ruby
   gem 'sinatra'
   gem 'httparty'
   ```

2. Create a new Ruby file (e.g., `web_server.rb`) and set up the Sinatra routes to handle incoming requests. Here's a basic setup:

   ```ruby
   require 'sinatra'
   require 'httparty'
   require 'dotenv/load'  # Load environment variables

   get '/' do
     'Server is running.'
   end

   get '/chapa_payment_verification' do
     # Extract necessary parameters from the query
     chat_id = params['chat_id']
     tx_ref = params['tx_ref']

     # Call method to verify the payment with Chapa
     verification_result = verify_chapa_transaction(tx_ref)

     # Construct the response based on the verification result
     if verification_result && verification_result['status'] == 'success'
       "Your payment was successful!"
     else
       "There was a problem with your payment."
     end
   end

   # Method to verify Chapa transaction
   def verify_chapa_transaction(tx_ref)
     response = HTTParty.get("#{ENV['PAYMENT_PROVIDER_CHAPA_VERIFY']}/#{tx_ref}",
                             headers: { 'Authorization' => "Bearer #{ENV['PAYMENT_PROVIDER_CHAPA_SECRET']}" })
     response.parsed_response if response.success?
   end
   ```

3. Run your Sinatra application by executing `ruby web_server.rb`. Ensure your firewall and routing settings allow incoming requests to the appropriate port (default is 4567).

### Ngrok for Local Development

Ngrok is a useful tool to create secure tunnels to your localhost, allowing you to expose your local development server to the internet. This is particularly useful for testing webhook callbacks. Follow these steps to use Ngrok:

1. Download and install Ngrok from [https://ngrok.com/download](https://ngrok.com/download).
2. Once installed, open a new terminal window and start your Sinatra application (or any other local server).
3. In another terminal window, start Ngrok by executing `./ngrok http 4567` assuming your local server runs on port 4567. Adjust the port number according to your server's configuration.
4. Ngrok will display a forwarding URL (e.g., `http://12345.ngrok.io`). Use this URL as your webhook URL for testing purposes.
5. Remember to update your environment variables or configurations to use the Ngrok URL for webhook callbacks during local development.

### Testing

Mock Redis in your test suite to avoid impacting real data. Ensure your tests validate Redis interactions accurately, enhancing confidence in data integrity and application logic.

## Troubleshooting

When integrating new features like Chapa payment processing or setting up webhook callbacks, you may encounter some common issues:

1. **Webhook Callbacks Not Received**: Ensure that your local server is running and accessible. If using Ngrok, verify that it is running and that the forwarding URL is correct and used in your bot's configuration.
2. **Payment Verification Fails**: Double-check your Chapa API credentials and ensure that the environment variables are correctly set. Verify that your server's route for handling verification is correctly implemented and accessible.
3. **Sinatra Server Errors**: Check the server logs for errors. Ensure that all required gems are installed and that there are no syntax errors in your script.
4. **Ngrok Tunnel Issues**: If Ngrok is not forwarding requests as expected, restart Ngrok and check for any error messages. Ensure your firewall or network settings are not blocking Ngrok's connections.

If problems persist, consult the documentation for each tool and consider reaching out to their respective support channels or community forums for assistance.

## License
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

**Attribution**: This project is published by Samael (AI Powered), 2024.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.

No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.
