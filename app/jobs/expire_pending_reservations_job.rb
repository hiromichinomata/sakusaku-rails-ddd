class ExpirePendingReservationsJob < ApplicationJob
  queue_as :default

  # お支払いの期限（予約から15分）を過ぎた仮予約を、期限切れにして席を戻す
  def perform
    Reservation.pending.where(created_at: ...15.minutes.ago).find_each do |reservation|
      Reservation.transaction do
        reservation.update!(status: :expired)
        Ticketing::ReleaseSeats.new.call(event_id: reservation.event_id, count: reservation.quantity)
      end
    end
  end
end
