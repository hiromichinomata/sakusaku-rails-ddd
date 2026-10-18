module Ticketing
  # ドメインイベント「予約が作られた」。申込が受け付けられたことを、ほかのコンテキストに知らせる
  class ReservationCreated < Data.define(:reservation_id, :event_id, :status, :occurred_at)
    def self.event_name
      "ticketing.reservation_created"
    end
  end
end
