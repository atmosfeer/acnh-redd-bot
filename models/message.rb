class Message < ActiveRecord::Base
  has_many :reactions
  has_many :art_pieces
  belongs_to :channel
  belongs_to :user

  def extract_art_pieces
    self.content.split("\n").select { |x| x.match /^\d/ }.map { |x| x.sub(/\d\.\s*/, '') }
  end

  def original_message_no_art
    self.content.gsub("i!new", "").gsub("I!new", "").split("\n").reject { |x| x.match /^\d/ }.join("\n")
  end

  def formatted_post(event)
    message_content = self.original_message_no_art
    message_content += "\nHost: #{event.user.mention}"
    message_content += "\n__________________"
    message_content += "\nItems:"
    self.art_pieces.each do |art_piece|
      message_content += "\n#{art_piece.number}. #{art_piece.name} (#{art_piece.status})"
    end
    message_content
  end
end

