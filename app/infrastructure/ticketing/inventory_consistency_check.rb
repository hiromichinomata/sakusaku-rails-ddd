module Ticketing
  # 残席の「予約済みの人数」と、有効な予約の人数の合計がずれていないかを調べる（第16章の 16.8）
  class InventoryConsistencyCheck
    Mismatch = Data.define(:event_id, :recorded, :actual)

    def call
      actual = ::Reservation.active.group(:event_id).sum(:quantity)

      TicketInventory.order(:event_id).filter_map do |inventory|
        counted = actual.fetch(inventory.event_id, 0)
        next if inventory.reserved_count == counted

        Mismatch.new(event_id: inventory.event_id, recorded: inventory.reserved_count, actual: counted)
      end
    end
  end
end
