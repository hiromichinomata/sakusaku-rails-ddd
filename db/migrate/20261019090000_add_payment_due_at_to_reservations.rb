class AddPaymentDueAtToReservations < ActiveRecord::Migration[8.1]
  def up
    # 支払い期限を、予約ごとに持つ。これまでの予約は、作成から15分後
    add_column :reservations, :payment_due_at, :datetime
    execute "UPDATE reservations SET payment_due_at = created_at + interval '15 minutes'"
    change_column_null :reservations, :payment_due_at, false
  end

  def down
    remove_column :reservations, :payment_due_at
  end
end
