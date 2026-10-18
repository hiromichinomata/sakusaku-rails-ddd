module Ticketing
  # 受付期間。イベントの開始時刻の前まで申込を受け付ける（R-04）
  class SalesPeriod < Data.define(:ends_at)
    class Closed < BusinessRuleViolation
      def initialize
        super("このイベントの受付は終了しました")
      end
    end

    def open_at?(time)
      time < ends_at
    end

    def ensure_open!(time)
      raise Closed unless open_at?(time)
    end
  end
end
