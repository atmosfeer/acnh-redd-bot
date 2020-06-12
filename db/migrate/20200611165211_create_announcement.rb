class CreateAnnouncement < ActiveRecord::Migration[6.0]
  def change
    create_table :announcements do |t|
      t.bigint :discord_id
      t.string :content
      t.references :user
      t.references :channel
      t.string :dodo

      t.timestamps
    end
  end
end
