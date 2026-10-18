class ExpirePendingReservationsJob < ApplicationJob
  queue_as :default

  # お支払いの期限（予約から15分）を過ぎた仮予約を、期限切れにして席を戻す
  def perform
    Reservation.pending.where(created_at: ...15.minutes.ago).update_all(status: "expired")
  end
end
