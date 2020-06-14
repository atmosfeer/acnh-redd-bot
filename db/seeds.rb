Dir[File.join(__dir__, '../models', '*.rb')].each { |file| require_relative file }

puts "Prepare for the cleanse!"

Reaction.destroy_all
ArtPiece.destroy_all
Announcement.destroy_all
Channel.destroy_all
User.destroy_all

puts "All clean now!"
