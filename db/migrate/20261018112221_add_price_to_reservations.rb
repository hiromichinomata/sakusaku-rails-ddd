class AddPriceToReservations < ActiveRecord::Migration[8.1]
  def up
    add_column :reservations, :price, :integer
    # 今ある予約には、今のイベントの料金を入れる
    execute <<~SQL
      UPDATE reservations SET price = events.price FROM events WHERE events.id = reservations.event_id
    SQL
    change_column_null :reservations, :price, false
  end

  def down
    remove_column :reservations, :price
  end
end
