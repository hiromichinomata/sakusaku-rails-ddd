module Ticketing
  # 抽選。申込を乱数の順に並べ、残席に入る申込から当選にする（R-13）
  class Lottery
    # 抽選の申込。申込者は、当選したときの予約に使う
    class Entry < Data.define(:id, :count, :applicant)
      def initialize(id:, count:, applicant: nil)
        super
      end
    end

    Result = Data.define(:winners, :losers)
    PAYMENT_WINDOW = 24 * 60 * 60 # 当選者の支払い期限は、抽選から24時間後（秒）

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
