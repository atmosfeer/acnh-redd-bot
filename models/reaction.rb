class Reaction < ActiveRecord::Base
  belongs_to :announcement
  belongs_to :user, optional: true
end
