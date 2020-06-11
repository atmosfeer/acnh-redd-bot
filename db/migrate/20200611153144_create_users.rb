class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.integer :discord_id
      t.string :discord_name
    end
  end
end
