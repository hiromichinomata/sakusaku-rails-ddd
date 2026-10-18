module Ticketing
  # 抽選する。当選者には仮予約を作って席を押さえ、落選者は落選にする（R-13）
  class DrawLottery
    def initialize(entries: LotteryEntryRepository.new, inventories: InventoryRepository.new,
                   reservations: ReservationRepository.new, sales_infos: SalesInfoReader.new)
      @entries = entries
      @inventories = inventories
      @reservations = reservations
      @sales_infos = sales_infos
    end

    def call(event_id:, random: Random.new, now: Time.current)
      ApplicationRecord.transaction do
        inventory = @inventories.find(event_id, lock: true)
        result = Lottery.new(seats: inventory.remaining_seats).draw(@entries.entered_for(event_id), random: random)

        price = @sales_infos.find(event_id).price
        result.winners.each { |entry| reserve_for(entry, inventory, price, now) }
        @entries.mark_lost(result.losers)
        @inventories.save(inventory)
        result
      end
    end

    private

    def reserve_for(entry, inventory, price, now)
      inventory.reserve(entry.count)
      reservation = @reservations.add(
        Reservation.apply(event_id: inventory.event_id, applicant: entry.applicant, count: entry.count, price: price,
                          reserved_at: now)
      )
      @entries.mark_won(entry, reservation_id: reservation.id)
      DomainEvents.publish(ReservationCreated.new(reservation_id: reservation.id, event_id: inventory.event_id,
                                                  status: reservation.status, occurred_at: now))
    end
  end
end
