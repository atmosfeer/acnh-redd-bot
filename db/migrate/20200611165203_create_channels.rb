class CreateChannels < ActiveRecord::Migration[6.0]
  def change
    create_table :channels do |t|
      t.bigint :discord_id
      t.string :discord_name

      t.timestamps
    end
  end
end
