class CreateTicketInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_inventories do |t|
      t.references :event, null: false, foreign_key: true, index: { unique: true }
      t.integer :capacity, null: false
      t.integer :reserved_count, null: false, default: 0

      t.timestamps
    end
    add_check_constraint :ticket_inventories, "reserved_count BETWEEN 0 AND capacity",
                         name: "reserved_count_within_capacity"

    reversible do |direction|
      direction.up do
        # 今あるイベントの残席を、有効な予約の人数の合計から作る
        execute <<~SQL
          INSERT INTO ticket_inventories (event_id, capacity, reserved_count, created_at, updated_at)
          SELECT events.id,
                 events.capacity,
                 COALESCE(SUM(reservations.quantity) FILTER (WHERE reservations.status IN ('pending', 'confirmed')), 0),
                 NOW(),
                 NOW()
          FROM events
          LEFT JOIN reservations ON reservations.event_id = events.id
          GROUP BY events.id
        SQL
      end
    end
  end
end
