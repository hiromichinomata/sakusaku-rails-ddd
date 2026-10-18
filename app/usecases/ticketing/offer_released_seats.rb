module Ticketing
  # 席が戻ったら、キャンセル待ちの人に案内する。登録の古い順に、入る人数の人へ仮予約を作る（R-14）
  class OfferReleasedSeats
    def initialize(entries: WaitlistEntryRepository.new, inventories: InventoryRepository.new,
                   reservations: ReservationRepository.new, sales_infos: SalesInfoReader.new)
      @entries = entries
      @inventories = inventories
      @reservations = reservations
      @allocate = AllocateSeats.new(reservations: reservations)
      @sales_infos = sales_infos
    end

    def call(event_id:, now: Time.current)
      ApplicationRecord.transaction do
        inventory = @inventories.find(event_id, lock: true)
        candidates = skip_already_reserved(event_id, @entries.waiting_for(event_id))

        price = @sales_infos.find(event_id).price
        Waitlist.new(candidates).offers_for(inventory.remaining_seats).each do |entry|
          reservation = @allocate.call(inventory: inventory, applicant: entry.applicant, count: entry.count,
                                       price: price, now: now)
          @entries.mark_offered(entry, reservation_id: reservation.id)
        end
        @inventories.save(inventory)
      end
    end

    private

    # すでに有効な予約がある人は、案内せずに飛ばす（R-03）
    def skip_already_reserved(event_id, entries)
      reserved, candidates = entries.partition do |entry|
        @reservations.active_exists?(event_id: event_id, email: entry.applicant.email)
      end
      @entries.mark_skipped(reserved)
      candidates
    end
  end
end
