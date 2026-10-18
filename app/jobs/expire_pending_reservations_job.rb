class ExpirePendingReservationsJob < ApplicationJob
  queue_as :default

  # 支払い期限を過ぎた仮予約を、1件ずつ期限切れにする
  def perform(now: Time.current)
    Reservation.pending.where(payment_due_at: ...now).find_each do |record|
      Ticketing::ExpireReservation.new.call(reservation_id: record.id, now: now)
    end
  end
end
