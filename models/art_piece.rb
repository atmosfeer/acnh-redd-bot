class ArtPiece < ActiveRecord::Base
  belongs_to :announcement
  belongs_to :user

  def reactions
    announcement.reactions
  end

  def update_status
    if reactions.empty?
      self.status = "open"
      self.user = nil
    else
      self.status = "claimed"
      self.user = reactions.order(created_at: :asc).first.user
    end
    save
  end
end
