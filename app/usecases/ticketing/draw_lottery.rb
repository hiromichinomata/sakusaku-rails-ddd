module Ticketing
  # 抽選する。当選者には仮予約を作って席を押さえ、落選者は落選にする（R-13）
  class DrawLottery
    def initialize(entries: LotteryEntryRepository.new, inventories: InventoryRepository.new,
                   allocate: AllocateSeats.new, sales_infos: SalesInfoReader.new)
      @entries = entries
      @inventories = inventories
      @allocate = allocate
      @sales_infos = sales_infos
    end

    def call(event_id:, random: Random.new, now: Time.current)
      ApplicationRecord.transaction do
        inventory = @inventories.find(event_id, lock: true)
        result = Lottery.new(seats: inventory.remaining_seats).draw(@entries.entered_for(event_id), random: random)

        price = @sales_infos.find(event_id).price
        result.winners.each do |entry|
          reservation = @allocate.call(inventory: inventory, applicant: entry.applicant, count: entry.count,
                                       price: price, now: now, payment_window: Lottery::PAYMENT_WINDOW)
          @entries.mark_won(entry, reservation_id: reservation.id)
        end
        @entries.mark_lost(result.losers)
        @inventories.save(inventory)
        result
      end
    end
  end
end
