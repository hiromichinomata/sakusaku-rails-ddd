module Notification
  # 予約のメールを送るジョブ。失敗しても申込には影響せず、ジョブとしてやり直せる
  class SendReservationMailJob < ApplicationJob
    queue_as :default

    def perform(reservation_id, kind)
      reservation = ::Reservation.find(reservation_id)
      ReservationMailer.with(reservation: reservation).public_send(kind).deliver_now
    end
  end
end
