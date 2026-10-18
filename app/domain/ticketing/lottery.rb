module Ticketing
  # 抽選。申込を乱数の順に並べ、残席に入る申込から当選にする（R-13）
  class Lottery
    Entry = Data.define(:id, :count)
    Result = Data.define(:winners, :losers)

    def initialize(seats:)
      @seats = seats
    end

    # random を渡すので、同じ乱数の種なら同じ結果になる
    def draw(entries, random:)
      remaining = @seats
      winners, losers = entries.shuffle(random: random).partition do |entry|
        next false if entry.count.to_i > remaining

        remaining -= entry.count.to_i
        true
      end
      Result.new(winners: winners, losers: losers)
    end
  end
end
