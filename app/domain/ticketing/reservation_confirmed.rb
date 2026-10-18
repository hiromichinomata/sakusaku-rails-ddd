module Ticketing
  # ドメインイベント「予約が確定した」。支払いが済んだことを、ほかのコンテキストに知らせる
  class ReservationConfirmed < Data.define(:reservation_id, :event_id, :occurred_at)
    def self.event_name
      "ticketing.reservation_confirmed"
    end
  end
end
