class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
