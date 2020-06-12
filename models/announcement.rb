class Announcement < ActiveRecord::Base
  has_many :reactions
  has_many :art_pieces
  belongs_to :channel
  belongs_to :user

  def extract_art_pieces
    self.content.split("\n").select { |x| x.match /^\d/ }.map { |x| x.sub(/\d\.\s*/, '') }
  end

  def original_message_no_art
    self.content.gsub("d!redd", "").gsub("Items:", "").split("\n").reject { |x| x.match /^\d/ }.join("\n")
  end

  def art_pieces_queue
    art_pieces = ""
    self.art_pieces.sort_by(&:number).each do |art_piece|
      art_pieces += "\n#{art_piece.number}. #{art_piece.name}"
    end
    art_pieces
  end

  def art_status
    status = ""
    self.art_pieces.sort_by(&:number).each do |art_piece|
      if art_piece.user
        status += "\n#{art_piece.number}. #{art_piece.status.capitalize} by #{art_piece.user.mention}"
      else
        status += "\n#{art_piece.number}. #{art_piece.status.capitalize}"
      end
    end
    status
  end

  def build_inline_fields
    [
      { name: "Host‎‎‎‎", value: user.mention + " ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿ ", inline: true },
      { name: "Available Art", value: self.art_pieces_queue + " ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿  ﻿", inline: true },
      { name: "Art Queue", value: self.art_status, inline: true }
    ]
  end
end
