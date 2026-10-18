module Ticketing
  # 二重予約を調べるドメインサービス（R-03）。
  # 1つの予約だけでは分からないので、予約のリポジトリに問い合わせる。
  class DoubleBookingCheck
    def initialize(reservations)
      @reservations = reservations
    end

    def ensure_not_double_booked!(event_id:, email:)
      raise Reservation::AlreadyReserved if @reservations.active_exists?(event_id: event_id, email: email)
    end
  end
end
