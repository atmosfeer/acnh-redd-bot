require 'sinatra'
require 'pry-byebug'
require 'sinatra/activerecord'
require 'discordrb'
require 'discordrb/webhooks'
require 'dotenv/load'

DEFAULT_MESSAGE = "Visitor: Redd
Location: Secret beach, remember a ladder
Shops: Yes
Dodo: Queue
Water: Yes please
Art Pieces:
1. Painting
2. Painting
3. Statue
4. Painting
Other: Free DIYs on the left + I'm afk"

class App < Sinatra::Base
  bot = Discordrb::Commands::CommandBot.new token: ENV['BOT_TOKEN']
  controller = BotController.new(bot)

  bot.command :redd do |event|
    content = event.content
    message = bot.send_message(ENV['CHANNEL_ID'], content)
    ["1️⃣", "2️⃣", "3️⃣", "4️⃣"].each do |emoji|
      message.react emoji
    end
  end

  bot.command :dodo do |event|
    binding.pry
    "dodo command called"
  end

  bot.command :giveaway do |event|
    content = event.content
    message = bot.send_message(ENV['CHANNEL_ID'], content)
    message.react "1️⃣"
    message.react "2️⃣"
    message.react "3️⃣"
    message.react "4️⃣"
  end

  bot.command :art do |event|
    # event << 'Art available to offer:'
    # event << ''
    # event << 'Paintings:'
    # event << 'Wild-left'
    # event << 'Wild-left'
    # event << 'Wild-left'
    # event << ''
    # event << 'Statues:'
    # event << 'Great-statue'
    # event << 'Great-statue'
    # event << 'Great-statue'
  end

  bot.run



  get '/' do
    'Monkey!'
  end
end

