module Ticketing
  # キャンセルや期限切れで、予約の席を残席に戻す
  class ReleaseSeats
    def initialize(inventories: InventoryRepository.new)
      @inventories = inventories
    end

    def call(event_id:, count:)
      inventory = @inventories.find(event_id)
      inventory.release(ReservationCount.new(count))
      @inventories.save(inventory)
    end
  end
end
