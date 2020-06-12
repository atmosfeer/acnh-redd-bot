class CreateReactions < ActiveRecord::Migration[6.0]
  def change
    create_table :reactions do |t|
      t.integer :number
      t.references :announcement
      t.references :user

      t.timestamps
    end
  end
end
