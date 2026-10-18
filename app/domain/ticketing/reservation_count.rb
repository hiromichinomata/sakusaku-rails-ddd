module Ticketing
  # 1件の予約の人数。サービス全体では1〜10人（主催者ごとの上限は ReservationPolicy）
  class ReservationCount < Data.define(:value)
    MIN = 1
    MAX = 10

    def initialize(value:)
      unless value.is_a?(Integer) && value.between?(MIN, MAX)
        raise ArgumentError, "人数は#{MIN}〜#{MAX}人で指定してください: #{value.inspect}"
      end

      super
    end

    def to_i
      value
    end

    def to_s
      "#{value}人"
    end
  end
end
