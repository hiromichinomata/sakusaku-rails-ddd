class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.integer :quantity, null: false
      t.string :status, null: false, default: "waiting" # waiting（待っている）・offered（案内した）・skipped（飛ばした）
      t.bigint :reservation_id

      t.timestamps
    end
    add_index :waitlist_entries, %i[event_id email], unique: true, where: "status = 'waiting'"
  end
end
