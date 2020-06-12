class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.bigint :discord_id
      t.string :discord_name
      t.boolean :in_queue, default: false
      t.boolean :active_post, default: false

      t.timestamps
    end
  end
end
