require 'sinatra'
require 'sinatra/activerecord'
require 'discordrb'
require 'discordrb/webhooks'
require 'dotenv/load'
require 'pry-byebug'

require_relative 'models/art_piece'
require_relative 'models/announcement'
require_relative 'models/channel'
require_relative 'models/user'
require_relative 'models/reaction'
require_relative 'controllers/bot_controller'

EMOJIS = ["1️⃣", "2️⃣", "3️⃣", "4️⃣"]

class App < Sinatra::Base
    bot = Discordrb::Commands::CommandBot.new token: ENV['BOT_TOKEN'], prefix: ["d!", "D!"], help_command: false

    controller = BotController.new(bot)

    bot.command :bot_status do |event|
      event.message.delete
      bot.game=("Type d!help")
      nil
    end

    bot.command :clear_channel do |event|
      event.message.delete
      controller.clear_channel(event)
    end

    bot.command :new do |event|
      controller.redd_command(event)
    end

    bot.command :queue do |event|
      controller.queue_command(event)
    end

    bot.command :buy do |event|
      controller.buy_command(event)
    end

    bot.command :remove do |event|
      controller.remove_command(event)
    end

    bot.command :delete do |event|
      controller.delete_command(event)
    end

    bot.command :purge do |event|
      bot.channel(event.channel).prune(99)
      Reaction.destroy_all
      ArtPiece.destroy_all
      Announcement.destroy_all
      Channel.destroy_all
      User.destroy_all
      nil
    end

    bot.command :template do |event|
      template = "d!new\n"
      template += "Visitor: Redd\n"
      template += "Shops:\n"
      template += "Water:\n"
      template += "Other:\n"
      template += "Items:\n"
      template += "1. <name_of_art_piece> (real/fake)\n"
      template += "2. <name_of_art_piece> (real/fake)\n"
      template += "3. <name_of_art_piece> (real/fake)\n"
      template += "4. <name_of_art_piece> (real/fake)\n"

      event.user.pm(template)
    end

    bot.command :art do |event|
      art = "**Complete list of art!**\n"

      art += "\n**Paintings:**\n"
      art += "Serene Painting\n"
      art += "Warm Painting\n"
      art += "Wistful\n"
      art += "Academic\n"
      art += "Graceful\n"
      art += "Calm\n"
      art += "Flowery\n"
      art += "Jolly\n"
      art += "Moody\n"
      art += "Famous\n"
      art += "Scary\n"
      art += "Dynamic\n"
      art += "Scenic\n"
      art += "Moving\n"
      art += "Amazing\n"
      art += "Quaint\n"
      art += "Solemn\n"
      art += "Basic\n"
      art += "Worthy\n"
      art += "Glowing\n"
      art += "Common\n"
      art += "Sinking\n"
      art += "Nice\n"
      art += "Proper\n"
      art += "Mysterious\n"
      art += "Twinkling\n"
      art += "Perfect\n"
      art += "Wild Left Half\n"
      art += "Wild Right Half\n"
      art += "Detailed\n"

      art += "\n**Statues:**\n"
      art += "Warrior\n"
      art += "Motherly\n"
      art += "Beautiful\n"
      art += "Familiar\n"
      art += "Robust\n"
      art += "Gallant\n"
      art += "Informative\n"
      art += "Rock-head\n"
      art += "Ancient\n"
      art += "Tremendous\n"
      art += "Valiant\n"
      art += "Mystic\n"
      art += "Great\n"

      art += "\nReal or fake? Check this link: https://www.polygon.com/animal-crossing-new-horizons-switch-acnh-guide/2020/4/23/21231433/redd-jolly-museum-art-fake-real-forgeries-list-complete-painting-statue"

      event.user.pm(art)
    end

    bot.command :help do |event|
      help = "**d!template**\n"
      help += "Will send you a template to copy paste and fill in. Easy peasy!\n"
      help += "\n**d!new**\n"
      help += "Creates a new queue post. **Imporatant**: make sure you follow the right format\n"
      help += "\n**d!queue <dodo_code>**\n"
      help += "This will activate your queue, don't type the <>. You can use the same command to update the dodo code!\n"
      help += "\n**d!buy**\n"
      help += "**DON'T** leave the queue, use this command to let people know you bought the art piece! The queue will update itself\n"
      help += "\n**d!remove @mention**\n"
      help += "The host can use this command if someone doesn't show up\n"
      help += "\n**d!art**\n"
      help += "Will send you a complete list of the art in the game, also a guide to know if your art is real or fake\n"
      help += "\n**d!delete**\n"
      help += "The host can close the queue at any time with this command\n"

      bot.send_message(event.channel.id, "Useful commands when using Redd", nil, { description: help, color: 0x12457E } )
      nil
    end

    bot.run

    get '/' do
      'Monkey!'
    end
end

