module Notification
  # 予約のドメインイベントを受け取って、申込者に送るメールのジョブを積む
  class ReservationMailSubscriber
    def call(event)
      kind =
        case event
        when Ticketing::ReservationCreated then event.status == :pending ? "payment_request" : "confirmed"
        when Ticketing::ReservationConfirmed then "confirmed"
        end

      SendReservationMailJob.perform_later(event.reservation_id, kind)
    end
  end
end
