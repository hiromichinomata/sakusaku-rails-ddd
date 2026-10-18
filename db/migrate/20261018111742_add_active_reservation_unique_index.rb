class AddActiveReservationUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    # 同じイベントに、同じメールアドレスの有効な予約は1件まで（R-03）
    add_index :reservations, %i[event_id email], unique: true,
                                                where: "status IN ('pending', 'confirmed')",
                                                name: "index_reservations_on_event_id_and_email_active"
  end
end
