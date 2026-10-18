module Ticketing
  # ドメインイベント「予約が期限切れになった」。支払い期限を過ぎて、席を戻したことを知らせる
  class ReservationExpired < Data.define(:reservation_id, :event_id, :occurred_at)
    def self.event_name
      "ticketing.reservation_expired"
    end
  end
end
