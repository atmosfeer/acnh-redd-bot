require 'sinatra'
require 'pry-byebug'
require 'sinatra/activerecord'
require 'discordrb'
require 'discordrb/webhooks'
require 'dotenv/load'

require_relative 'models/art_piece'
require_relative 'models/announcement'
require_relative 'models/channel'
require_relative 'models/user'
require_relative 'models/reaction'
require_relative 'controllers/bot_controller'

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

EMOJIS = ["1️⃣", "2️⃣", "3️⃣", "4️⃣"]

class App < Sinatra::Base
  bot = Discordrb::Commands::CommandBot.new token: ENV['BOT_TOKEN'], prefix: "d!"
  controller = BotController.new(bot)

  bot.command :redd do |event|
    controller.redd_command(event)
  end

  bot.command :queue do |event|
    channel = bot.channel(ENV['CHANNEL_ID'])
    dodo = event.content.downcase.gsub("d!queue","").strip.match(/\w{5}/).to_s.upcase
    event.message.delete
    return "Oops, I think your forgot the dodo code, or maybe you typed it wrong? Try again!" if dodo.empty?
    user = User.find_by_discord_id(event.user.id)
    announcement_message = Announcement.where(user: user).last
    if announcement_message.dodo
      claimed_art_pieces = announcement_message.art_pieces.where(status: "claimed")
      user_ids = claimed_art_pieces.map(&:user).map(&:discord_id)
      claimed_users = channel.users.select { |user| user_ids.any? { |id| id == user.id } }
      claimed_users.each do |claimed_user|
        claimed_user.pm("Sorry about the inconvenience. #{user.mention}'s island is back up. Here's the new dodo code: #{dodo}")
      end
      bot.send_message(event.channel.id, "", nil, { description: "Dodo code updated!", color: 0x12457E } )
    else
      bot.send_message(event.channel.id, "", nil, { description: "Post succesfully created!", color: 0x12457E } )
    end
    announcement_message.dodo = dodo
    announcement_message.save!
    bot_message = channel.load_message(announcement_message.discord_id)
    EMOJIS.first(announcement_message.art_pieces.count).each do |emoji|
      bot_message.react emoji
    end
    nil
  end

  bot.command :buy do |event|
    channel = bot.channel(ENV['CHANNEL_ID'])
    user = User.find_by_discord_id(event.user.id)
    bought_art = user.art_pieces.where(status: "claimed").first
    bought_art.status = "bought"
    bought_art.save!
    user.in_queue = false
    user.save!
    announcement_message = bought_art.announcement
    bot_message = channel.load_message(bought_art.announcement.discord_id)
    bot_message.edit("", { description: announcement_message.original_message_no_art, fields: announcement_message.build_inline_fields })
    bot.send_message(event.channel.id, "", nil, { description: "Thank you for using this service! The queue is now updated!", color: 0x12457E } )
  end

  bot.command :remove do |event|
    author = User.find_by_discord_id(event.user.id)
    return "Sorry! You don't have an active post!" unless author.active_post
    mentioned_user = event.message.mentions.first
    user_to_remove = User.find_by_discord_id(mentioned_user.id)
    return "The user you tried to remove is currently not in a queue" unless user_to_remove && user_to_remove.in_queue
    announcement_message = author.announcements.last
    return "The person you mentioned is not in your queue" unless author.can_remove?(user_to_remove)
    channel = bot.channel(ENV['CHANNEL_ID'])
    user_to_remove.in_queue = false
    user_to_remove.save!
    reaction_to_remove = user_to_remove.reactions.where(announcement: announcement_message).first
    bot_message = channel.load_message(announcement_message.discord_id)
    bot_message.delete_reaction(user_to_remove.discord_id, EMOJIS[reaction_to_remove.number - 1])
    art_piece = announcement_message.art_pieces.where(number: reaction_to_remove.number).first
    art_piece.status = "open"
    art_piece.save!
    bot_message.edit("", { description: announcement_message.original_message_no_art, fields: announcement_message.build_inline_fields })
    bot.send_message(event.channel.id, "", nil, { description: "You succesfully removed #{user_to_remove.mention} from the queue!", color: 0x12457E } )
    reaction_to_remove.destroy!
    nil
  end

  bot.command :delete do |event|
    channel = bot.channel(ENV['CHANNEL_ID'])
    author = User.find_by_discord_id(event.user.id)
    return "You don't have an active post to delete" unless author
    return "You don't have an active post to delete" unless author.active_post
    announcement_message = author.announcements.last
    bot_message = channel.load_message(announcement_message.discord_id)
    if bot_message
      bot_message.delete
    else
      "Please contact a mod, something went wrong!"
    end
    author.active_post = false
    author.save!
    if announcement_message.reactions
      announcement_message.reactions.each do |reaction|
        reaction.user.in_queue = false
        reaction.user.save!
      end
    end
    bot.send_message(event.channel.id, "", nil, { description: "Post succesfully deleted!", color: 0x12457E } )
  end

  bot.command :template do |event|
    template = "Visitor: Redd\n"
    template += "Location: Secret beach\n"
    template += "Shops:\n"
    template += "Water:\n"
    template += "Dodo: Queue\n"
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
    help += "\n**d!redd**\n"
    help += "Creates a new queue post. **Imporatant**: make sure you follow the right format\n"
    help += "\n**d!queue <dodo_code>**\n"
    help += "This will activate your queue, don't type the <>. You can use the same command to update the dodo code!\n"
    help += "\n**d!buy**\n"
    help += "**Don't** leave the queue, use this command to let people know you bought the art piece! The queue will update.\n"
    help += "\n**d!remove**\n"
    help += "The host can use this command if someone doesn't show up\n"
    help += "\n**d!art**\n"
    help += "Will send you a complete list of the art in the game, also a guide to know if your art is real or fake.\n"
    help += "\n**d!delete**\n"
    help += "The host can close the queue at any time with this command.\n"

    bot.send_message(event.channel.id, "Useful commands when using Redd", nil, { description: help, color: 0x12457E } )
  end

  bot.command :clean do |event|
    event.channel.delete_messages(99, strict = false)
  end

  bot.run

  get '/' do
    'Monkey!'
  end
end

