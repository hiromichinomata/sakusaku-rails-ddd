module Ticketing
  # 予約。ID で見分けるエンティティ
  class Reservation
    # 同じイベントに、同じメールアドレスの有効な予約がすでにある（R-03）
    class AlreadyReserved < BusinessRuleViolation
      def initialize
        super("このメールアドレスでは、すでに予約があります")
      end
    end

    attr_reader :id, :event_id, :applicant, :count, :price, :status

    def initialize(event_id:, applicant:, count:, price:, id: nil, status: :pending)
      @id = id
      @event_id = event_id
      @applicant = applicant
      @count = count
      @price = price
      @status = status
    end

    def total_price
      price * count.to_i
    end

    def ==(other)
      return equal?(other) if id.nil?

      other.is_a?(Reservation) && other.id == id
    end
    alias eql? ==

    def hash
      id.nil? ? super : [ Reservation, id ].hash
    end
  end
end
