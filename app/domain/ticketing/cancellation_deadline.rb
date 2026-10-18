module Ticketing
  # 返金期限。開始時刻の◯時間前まで（ちょうどを含む）にキャンセルすれば、全額返金する（R-09）
  class CancellationDeadline < Data.define(:starts_at, :hours_before_start)
    HOURS_BEFORE_START = 72 # 主催者が決めていないとき

    def initialize(starts_at:, hours_before_start: HOURS_BEFORE_START)
      super
    end

    def refund_until
      starts_at - (hours_before_start * 60 * 60)
    end

    def refundable_at?(time)
      time <= refund_until
    end
  end
end
