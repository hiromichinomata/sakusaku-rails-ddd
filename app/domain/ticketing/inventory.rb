module Ticketing
  # 残席。イベントごとに、定員と予約済みの人数を持つ集約ルート。
  # 「予約済みの人数は定員を超えない（R-01）」をこのクラスだけで守る。
  class Inventory
    class NotEnoughSeats < BusinessRuleViolation
      attr_reader :remaining_seats

      def initialize(remaining_seats)
        @remaining_seats = remaining_seats
        super("残りの席数（#{remaining_seats}席）を超えています")
      end
    end

    class CapacityBelowReserved < BusinessRuleViolation
      def initialize(reserved_count)
        super("定員は予約済みの人数（#{reserved_count}人）より少なくできません")
      end
    end

    attr_reader :event_id, :capacity, :reserved_count

    def initialize(event_id:, capacity:, reserved_count: 0)
      unless reserved_count.between?(0, capacity)
        raise ArgumentError, "予約済みの人数（#{reserved_count}）が定員（#{capacity}）の範囲にありません"
      end

      @event_id = event_id
      @capacity = capacity
      @reserved_count = reserved_count
    end

    def remaining_seats
      capacity - reserved_count
    end

    def reserve(count)
      raise NotEnoughSeats, remaining_seats if count.to_i > remaining_seats

      @reserved_count += count.to_i
    end

    def release(count)
      @reserved_count = [ reserved_count - count.to_i, 0 ].max
    end

    def change_capacity(new_capacity)
      raise CapacityBelowReserved, reserved_count if new_capacity < reserved_count

      @capacity = new_capacity
    end
  end
end
