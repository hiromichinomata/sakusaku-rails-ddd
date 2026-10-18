module Ticketing
  # 抽選の当選やキャンセル待ちの案内で、申込者のために席を押さえて仮予約を作る。
  # 呼び出す側のトランザクションの中で、ロックした残席を渡して使う
  class AllocateSeats
    def initialize(reservations: ReservationRepository.new)
      @reservations = reservations
    end

    def call(inventory:, applicant:, count:, price:, now:)
      inventory.reserve(count)
      reservation = @reservations.add(
        Reservation.apply(event_id: inventory.event_id, applicant: applicant, count: count, price: price,
                          reserved_at: now)
      )
      DomainEvents.publish(ReservationCreated.new(reservation_id: reservation.id, event_id: inventory.event_id,
                                                  status: reservation.status, occurred_at: now))
      reservation
    end
  end
end
