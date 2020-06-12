class Channel < ActiveRecord::Base
  has_many :announcements
end
