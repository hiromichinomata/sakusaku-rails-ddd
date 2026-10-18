module Ticketing
  # 支払い期限を過ぎた仮予約を、期限切れにして席を戻す
  class ExpireReservation
    def initialize(reservations: ReservationRepository.new, inventories: InventoryRepository.new)
      @reservations = reservations
      @inventories = inventories
    end

    def call(reservation_id:, now: Time.current)
      ApplicationRecord.transaction do
        reservation = @reservations.find(reservation_id)
        reservation.expire(now: now)
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
