class BotController
  def initialize(bot)
    @bot = bot
  end

  def redd_command(event)
    user = set_user(event)
    # channel = Channel.find_by_discord_id(event.channel.id)
    return "Sorry you already have an active post, delete that first with d!delete before creating a new one." if user.active_post
    return "Hmm. Please check if your post matches the template in #art-announcements or type d!template" unless event.content.include?("1.")
    return "Sorry you're in the queue for a different post, please finish that before you enter a queue!" if user.in_queue

    announcement_message = Announcement.create!(content: event.content, user: user)
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

  def queue_command
  end

  private

  def set_user(event)
    user = User.find_by_discord_id(event.user.id)
    user ? user : User.create!(discord_id: event.user.id, discord_name: event.user.username)
  end

  def remove_reaction_event_listener(bot_message)
     EMOJIS.each_with_index do |emoji, i|
      @bot.reaction_remove(attributes = { emoji: emoji }) do |event|
        user = set_user(event)
        user.in_queue = false
        user.save!
        art_piece = reacted_message.art_pieces.where(number: i + 1).first
        reacted_message = Announcement.find_by_discord_id(event.message.id)
        reaction = user.reactions.where(announcement: reacted_message).first
        reaction.destroy! unless art_piece.status == "bought"
        art_piece.update_status unless art_piece.status == "bought"
        bot_message.edit("", { description: reacted_message.original_message_no_art, fields: reacted_message.build_inline_fields })
      end
    end
  end

  def add_reaction_event_listener(bot_message)
    EMOJIS.each_with_index do |emoji,i|
      @bot.reaction_add(attributes = { emoji: emoji }) do |event|
        user = set_user(event)
        reacted_message = Announcement.find_by_discord_id(event.message.id)
        if user.in_queue
          event.user.pm("Ooops! You're already in a another queue.")
          bot_message.delete_reaction(user.discord_id, emoji)
          return nil
        end
        art_piece = reacted_message.art_pieces.where(number: i + 1).first
        if user.can_react?(art_piece)
          user.in_queue = true
          user.save!
          Reaction.create!(number: i + 1, announcement: reacted_message, user: user)
          art_piece.update_status
          bot_message.edit("", { description: reacted_message.original_message_no_art, fields: reacted_message.build_inline_fields })
          event.user.pm("Get ready pick up your art at #{reacted_message.user.mention}'s island! Dodo code is: #{reacted_message.dodo}")
        else
          bot_message.delete_reaction(user.discord_id, emoji)
          event.user.pm("Sorry! You can't claim this!")
        end
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
