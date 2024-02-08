
# Ruby Telegram Bot

This Ruby Telegram Bot is a simple yet powerful tool designed to interact with users on the Telegram platform. Utilizing the Telegram Bot API, this bot is capable of responding to specific commands with pre-defined messages, making it ideal for a wide range of applications from customer support to entertainment services.

## Features

- **Command Recognition**: The bot recognizes commands such as `/start` and `/help`, responding with customized messages.
- **User Greeting**: Personalized greeting message using the user's first name upon initiating the conversation with `/start`.
- **Help Support**: Provides usage instructions or support information when the `/help` command is issued.

## Installation

To set up the Ruby Telegram Bot on your local machine, follow these steps:

1. **Clone the Repository**
   
   ```bash
   git clone https://github.com/samzhab/test_telegram_bot.git
   cd test_telegram_bot
   ```

2. **Install Dependencies**
   
   Ensure you have Ruby installed on your system. Then, run:
   
   ```bash
   bundle install
   ```

3. **Environment Variables**
   
   Create a `.env` file in the root directory of the project and add your Telegram Bot API key:
   
   ```
   TELEGRAM_BOT_API_KEY=your_api_key_here
   ```

   Note: This file is not tracked by Git to protect your API key.

4. **Running the Bot**

   To start the bot, execute:
   
   ```bash
   ruby telegram_bot.rb
   ```

## Usage

After starting the bot, it will listen for messages sent by users. Available commands include:

- `/start` - Sends a welcome message to the user.
- `/help` - Provides information on how to interact with the bot.

## Development

To contribute to the bot or modify its behavior:

- **Modifying Responses**: Edit the `respond_to_message` method in `telegram_bot.rb`.
- **Adding Commands**: Implement additional `when` cases within the `respond_to_message` method.

## Testing

The project includes a spec file (`telegram_bot_spec.rb`) for testing the bot's response functionality. Run the tests with:

```bash
rspec spec/telegram_bot_spec.rb
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for further discussion.

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
