module Ticketing
  # 申込者のキャンセル。予約をキャンセル済みにして、席を戻す
  class CancelReservation
    def initialize(reservations: ReservationRepository.new, inventories: InventoryRepository.new)
      @reservations = reservations
      @inventories = inventories
    end

    def call(reservation_id:, now: Time.current)
      ApplicationRecord.transaction do
        reservation = @reservations.find(reservation_id)
        reservation.cancel
        @reservations.save(reservation)
        release_seats(reservation)
        reservation
      end
    end

    private

    def release_seats(reservation)
      inventory = @inventories.find(reservation.event_id)
      inventory.release(reservation.count)
      @inventories.save(inventory)
    end
  end
end
