class User < ActiveRecord::Base
  has_many :announcements
  has_many :art_pieces
  has_many :reactions

  validates :discord_id, presence: true
  validates :discord_id, uniqueness: true

  def mention
    "<@#{self.discord_id}>"
  end

  def can_react?(art_piece)
    art_piece.status == "open" &&
    art_piece.announcement.reactions.where(user: self).count < 1
  end

  def can_remove?(other_user)
    other_user != self && !other_user.art_pieces.where(announcement: current_announcement).empty?
  end

  def current_announcement
    announcements.last
  end
end
