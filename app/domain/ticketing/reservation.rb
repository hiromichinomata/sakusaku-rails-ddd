module Ticketing
  # 予約。ID で見分けるエンティティ
  class Reservation
    attr_reader :id, :event_id, :name, :email, :count, :price, :status

    def initialize(event_id:, name:, email:, count:, price:, id: nil, status: :pending)
      @id = id
      @event_id = event_id
      @name = name
      @email = email
      @count = count
      @price = price
      @status = status
    end

    def total_price
      price * count
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
