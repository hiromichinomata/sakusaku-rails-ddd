class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :venue
      t.datetime :starts_at, null: false
      t.integer :capacity, null: false
      t.integer :price, null: false

      t.timestamps
    end
  end
end
