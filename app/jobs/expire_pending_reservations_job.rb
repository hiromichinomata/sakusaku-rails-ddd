class ExpirePendingReservationsJob < ApplicationJob
  queue_as :default

  # 支払い期限を過ぎた仮予約を、1件ずつ期限切れにする
  def perform(now: Time.current)
    deadline_passed = now - Ticketing::Reservation::PAYMENT_WINDOW
    Reservation.pending.where(created_at: ...deadline_passed).find_each do |record|
      Ticketing::ExpireReservation.new.call(reservation_id: record.id, now: now)
    end
  end
end
