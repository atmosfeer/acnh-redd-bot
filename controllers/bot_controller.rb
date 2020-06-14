require 'pry-byebug'

class BotController
  def initialize(bot)
    @bot = bot
  end

  def redd_command(event)
    user = set_user(event)
    announcement_message = Announcement.create!(content: event.content, user: user)
    # channel = Channel.find_by_discord_id(event.channel.id)
    return "Sorry you already have an active post, delete that first with d!delete before creating a new one." if user.active_post
    return "Hmm. Please check if your post matches the template in #art-announcements or type d!template" unless event.content.include?("1.")
    return "Sorry you're in the queue for a different post, please finish that before you enter a queue!" if user.in_queue
    if announcement_message.original_message_no_art.empty? || announcement_message.original_message_no_art.length < 20
      @bot.send_message(event.channel.id, "", nil, { description: "Please add a description like in the d!template to your post, it seems to be empty or too short.", color: 0x12457E } )
      nil
    end
    user.active_post = true
    user.save!
    art_pieces = announcement_message.extract_art_pieces
    art_pieces.each_with_index do |art,i|
      ArtPiece.create!(name: art, number: i + 1, status: "open", announcement: announcement_message)
    end

    bot_message = @bot.send_message(ENV['CHANNEL_ID'], "", nil, { description: announcement_message.original_message_no_art, fields: announcement_message.build_inline_fields, color: 0x12457E } )
    announcement_message.discord_id = bot_message.id
    announcement_message.save!

    add_reaction_event_listener(bot_message)
    remove_reaction_event_listener(bot_message)
    add_edit_event_listener(bot_message)

    @bot.send_message(event.channel.id, "", nil, { description: "Succesfully created! Check out #art-announcements. Use d!queue <dodo_code> to activate the post!", color: 0x12457E } )

    nil
  end

  def queue_command(event)
    user = set_user(event)
    channel = set_channel
    announcement_message = Announcement.where(user: user).last
    # if the user has no current post
    if !user.active_post
      event.message.delete
      @bot.send_message(event.channel.id, "", nil, { description: "You don't have a post to add a queue for, use d!new to start a new post" , color: 0x12457E } )
      nil
    end
    # Format the dodo code
    dodo = event.content.downcase.gsub("d!queue","").gsub("D!queue","").strip.match(/\w{5}/).to_s.upcase
    event.message.delete
    # If the user types in the wrong dodo
    if dodo.empty?
      @bot.send_message(event.channel.id, "", nil, { description: "Oops, I think your forgot to include the dodo, or maybe you typed it wrong? Try again! Remember it's d!queue <dodo_code>. No brackets." , color: 0x12457E } )
      nil
    end
    # If the dodo is provided, either add it to the db or update the current dodo
    if announcement_message.dodo
      claimed_art_pieces = announcement_message.art_pieces.where(status: "claimed")
      user_ids = claimed_art_pieces.map(&:user).map(&:discord_id)
      claimed_users = channel.users.select { |user| user_ids.any? { |id| id == user.id } }
      claimed_users.each do |claimed_user|
        claimed_user.pm("Sorry for the inconvenience. #{user.mention}'s island is back up. Here's the new dodo code: #{dodo}")
      end
      @bot.send_message(event.channel.id, "", nil, { description: "Dodo code updated!", color: 0x12457E } )
    else
      @bot.send_message(event.channel.id, "", nil, { description: "Gotcha! Your post is now active!", color: 0x12457E } )
    end
    announcement_message.dodo = dodo
    announcement_message.save!
    # Add the reactions to the post
    bot_message = channel.load_message(announcement_message.discord_id)
    EMOJIS.first(announcement_message.art_pieces.count).each do |emoji|
      bot_message.react emoji
    end
    nil
  end

  def buy_command(event)
    channel = set_channel
    user = User.find_by_discord_id(event.user.id)
    if !user.in_queue
      @bot.send_message(event.channel.id, "", nil, { description: "Sorry! You haven't claimed any art that you can mark as bought.", color: 0x12457E } )
      nil
    end
    bought_art = user.art_pieces.where(status: "claimed").first
    bought_art.status = "bought"
    bought_art.save!
    user.in_queue = false
    user.save!
    announcement_message = bought_art.announcement
    bot_message = channel.load_message(bought_art.announcement.discord_id)
    bot_message.edit("", { description: announcement_message.original_message_no_art, fields: announcement_message.build_inline_fields })
    @bot.send_message(event.channel.id, "", nil, { description: "Pleasure doin' business with you cousin! I updated the queue as well, no need to do more, thanks!", color: 0x12457E } )
  end

  def remove_command(event)
    author = User.find_by_discord_id(event.user.id)
    mentioned_user = event.message.mentions.first
    user_to_remove = User.find_by_discord_id(mentioned_user.id)
    announcement_message = author.announcements.last
    channel = set_channel
    return "Sorry! You don't have an active post!" unless author.active_post
    return "The user you tried to remove is currently not in a queue." unless user_to_remove && user_to_remove.in_queue
    return "The person you mentioned is not in your queue." unless author.can_remove?(user_to_remove)
    user_to_remove.in_queue = false
    user_to_remove.save!
    reaction_to_remove = user_to_remove.reactions.where(announcement: announcement_message).first
    bot_message = channel.load_message(announcement_message.discord_id)
    bot_message.delete_reaction(user_to_remove.discord_id, EMOJIS[reaction_to_remove.number - 1])
    art_piece = announcement_message.art_pieces.where(number: reaction_to_remove.number).first
    art_piece.status = "open"
    art_piece.save!
    bot_message.edit("", { description: announcement_message.original_message_no_art, fields: announcement_message.build_inline_fields })
    @bot.send_message(event.channel.id, "", nil, { description: "You succesfully removed #{user_to_remove.mention} from the queue!", color: 0x12457E } )
    reaction_to_remove.destroy!
    nil
  end

  def delete_command(event)
    channel = set_channel
    author = set_user(event)
    announcement_message = author.announcements.last
    bot_message = channel.load_message(announcement_message.discord_id)
    # return "You don't have an active post to delete" unless author
    return "You don't have an active post to delete" unless author.active_post
    if bot_message
      bot_message.delete
      @bot.send_message(event.channel.id, "", nil, { description: "Post succesfully deleted!", color: 0x12457E } )
    else
      @bot.send_message(event.channel.id, "", nil, { description: "Oops! Something went wrong.", color: 0x12457E } )
    end

    if announcement_message.reactions
      announcement_message.reactions.each do |reaction|
        reaction.user.in_queue = false
        reaction.user.save!
      end
    end

    author.active_post = false
    author.save!
    nil
  end

  def clear_channel(event)
    channel = event.channel
    channel.prune(99, strict = false) { |message| nil }
    nil
  end

  private

  def set_user(event)
    user = User.find_by_discord_id(event.user.id)
    user ? user : User.create!(discord_id: event.user.id, discord_name: event.user.username)
  end

  def set_channel
    @bot.channel(ENV['CHANNEL_ID'])
  end

  def remove_reaction_event_listener(bot_message)
    owner = Announcement.find_by(discord_id: bot_message.id).user
    EMOJIS.each_with_index do |emoji, i|
      #@bot.reaction_add(emoji: emoji) do |event|
        # user = set_user(event)
        # reacted_message = Announcement.find_by_discord_id(event.message.id)
        # return "Ooops, you're trying to queue for your own post!" if reacted_message.user == event.message.user
        # art_piece = reacted_message.art_pieces.where(number: i + 1).first
        # reaction = user.reactions.where(announcement: reacted_message).first
        # if reaction
        #   reaction.destroy! unless art_piece.status == "bought"
        # end
        # art_piece.update_status unless art_piece.status == "bought"
        # event.message.edit("", { description: reacted_message.original_message_no_art, fields: reacted_message.build_inline_fields })
        # user.in_queue = false
        # user.save!
      # end
    end
  end

  def add_reaction_event_listener(bot_message)

    EMOJIS.each_with_index do |emoji,i|
      @bot.reaction_add(emoji: emoji) do |event|
        owner = Announcement.find_by(discord_id: event.message.id).user
        reacted_message = Announcement.find_by(user: owner)
        p owner
        if owner
          p "This is the right post"
          nil
        end
        p "this is not the right post"
        # new_bot_message = event.message
        # user = set_user(event)
        # if user.in_queue
        #   event.user.pm("Ooops! You're already in a another queue.")
        #   new_bot_message.delete_reaction(user.discord_id, emoji)
        #   return nil
        # end
        # art_piece = reacted_message.art_pieces.where(number: i + 1).first
        # if user.can_react?(art_piece)
        #   Reaction.create!(number: i + 1, announcement: reacted_message, user: user)
        #   art_piece.update_status
        #   new_bot_message.edit("", { description: reacted_message.original_message_no_art, fields: reacted_message.build_inline_fields })
        #   event.user.pm("Get ready pick up your art at #{reacted_message.user.mention}'s island! Dodo code is: #{reacted_message.dodo}")
        #   user.in_queue = true
        #   user.save!
        # else
        #   new_bot_message.delete_reaction(user.discord_id, emoji)
        #   event.user.pm("Sorry! You can't claim this! If you don't know why, please ask a moderator!")
        # end
      end
    end
  end

  def add_edit_event_listener(bot_message)
    @bot.message_edit(attributes = { id: bot_message.id }) do |event|
      edited_message = Announcement.find_by_discord_id(bot_message.id)
      edited_message.content = event.message.content
      edited_message.save
      bot_message.edit("", { description: edited_message.original_message_no_art, fields: edited_message.build_inline_fields })
    end
  end
end

