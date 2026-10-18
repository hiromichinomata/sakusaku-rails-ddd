class AddLottery < ActiveRecord::Migration[8.1]
  def change
    # 売り方。first_come（先着）か lottery（抽選）
    add_column :ticket_inventories, :sales_method, :string, null: false, default: "first_come"

    create_table :lottery_entries do |t|
      t.references :event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.integer :quantity, null: false
      t.string :status, null: false, default: "entered" # entered（申込済み）・won（当選）・lost（落選）
      t.bigint :reservation_id

      t.timestamps
    end
    add_index :lottery_entries, %i[event_id email], unique: true
  end
end
