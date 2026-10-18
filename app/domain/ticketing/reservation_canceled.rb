module Ticketing
  # ドメインイベント「予約がキャンセルされた」。返金する金額（返金しないなら nil）も知らせる
  class ReservationCanceled < Data.define(:reservation_id, :event_id, :refund_amount, :occurred_at)
    def self.event_name
      "ticketing.reservation_canceled"
    end
  end
end
