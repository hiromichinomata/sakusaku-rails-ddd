class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :reservation, null: false, foreign_key: true, index: { unique: true }
      t.integer :amount, null: false
      t.string :charge_id, null: false
      t.string :refund_id
      t.string :status, null: false, default: "paid"

      t.timestamps
    end
  end
end
