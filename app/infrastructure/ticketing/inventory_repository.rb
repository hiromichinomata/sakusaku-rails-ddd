module Ticketing
  # 残席（Inventory）を ticket_inventories テーブルに保存し、読み込む
  class InventoryRepository
    # lock: true なら、トランザクションが終わるまで、ほかの人がこの残席を読んで変えるのを待たせる
    def find(event_id, lock: false)
      to_entity(TicketInventory.lock(lock).find_by!(event_id: event_id))
    rescue ActiveRecord::RecordNotFound
      raise NotFound, "イベント #{event_id} の残席が見つかりません"
    end

    def add(inventory)
      TicketInventory.create!(event_id: inventory.event_id, capacity: inventory.capacity,
                              reserved_count: inventory.reserved_count)
    end

    def save(inventory)
      TicketInventory.where(event_id: inventory.event_id)
                     .update_all(capacity: inventory.capacity, reserved_count: inventory.reserved_count,
                                 updated_at: Time.current)
    end

    private

    def to_entity(record)
      Inventory.new(event_id: record.event_id, capacity: record.capacity, reserved_count: record.reserved_count)
    end
  end
end
