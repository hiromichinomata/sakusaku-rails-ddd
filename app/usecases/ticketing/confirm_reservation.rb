module Ticketing
  # 支払いが済んだ仮予約を、予約確定にする
  class ConfirmReservation
    def initialize(reservations: ReservationRepository.new)
      @reservations = reservations
    end

    def call(reservation_id:, now: Time.current)
      ApplicationRecord.transaction do
        reservation = @reservations.find(reservation_id)
        reservation.confirm(now: now)
        @reservations.save(reservation)
        DomainEvents.publish(ReservationConfirmed.new(reservation_id: reservation.id, event_id: reservation.event_id,
                                                      occurred_at: now))
        reservation
      end
    end
  end
end
