puts "prepare for the cleanse!"

Dir["/Users/atmosfeer/code/acnh-redd-bot/models/*.rb"].each {|file| require_relative file }

Reaction.destroy_all
ArtPiece.destroy_all
Announcement.destroy_all
Channel.destroy_all
User.destroy_all
