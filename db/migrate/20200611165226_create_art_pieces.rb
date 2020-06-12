class CreateArtPieces < ActiveRecord::Migration[6.0]
  def change
    create_table :art_pieces do |t|
      t.string :name
      t.integer :number
      t.string :status
      t.references :announcement
      t.references :user

      t.timestamps
    end
  end
end
