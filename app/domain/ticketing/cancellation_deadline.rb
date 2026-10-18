module Ticketing
  # 返金期限。開始時刻の72時間前まで（ちょうどを含む）にキャンセルすれば、全額返金する（R-09）
  class CancellationDeadline < Data.define(:starts_at)
    HOURS_BEFORE_START = 72

    def refund_until
      starts_at - (HOURS_BEFORE_START * 60 * 60)
    end

    def refundable_at?(time)
      time <= refund_until
    end
  end
end
