module Ticketing
  # 申込者のキャンセル。予約をキャンセル済みにして、席を戻し、返金するかを決める
  class CancelReservation
    # refund_amount は返金する金額。返金しないときは nil
    Result = Data.define(:reservation, :refund_amount)

    def initialize(reservations: ReservationRepository.new, inventories: InventoryRepository.new,
                   sales_infos: SalesInfoReader.new)
      @reservations = reservations
      @inventories = inventories
      @sales_infos = sales_infos
    end

    def call(reservation_id:, now: Time.current)
      ApplicationRecord.transaction do
        reservation = @reservations.find(reservation_id)
        refund_amount = refund_amount_for(reservation, now)

        reservation.cancel
        @reservations.save(reservation)
        release_seats(reservation)
        DomainEvents.publish(ReservationCanceled.new(reservation_id: reservation.id, event_id: reservation.event_id,
                                                     refund_amount: refund_amount, occurred_at: now))
        Result.new(reservation: reservation, refund_amount: refund_amount)
      end
    end

    private

    # 予約確定で、支払い金額があり、返金期限までなら全額を返金する（R-09）
    def refund_amount_for(reservation, now)
      return nil unless reservation.status == :confirmed && !reservation.total_price.zero?

      deadline = @sales_infos.find(reservation.event_id).cancellation_deadline
      reservation.total_price if deadline.refundable_at?(now)
    end

    def release_seats(reservation)
      inventory = @inventories.find(reservation.event_id, lock: true)
      inventory.release(reservation.count)
      @inventories.save(inventory)
    end
  end
end
