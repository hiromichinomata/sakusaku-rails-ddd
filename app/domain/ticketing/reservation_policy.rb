module Ticketing
  # 主催者ごとの予約のルール。1回の予約の人数の上限（R-02）と、返金期限（R-09）
  class ReservationPolicy < Data.define(:max_count, :refund_hours_before_start)
    class TooManyAttendees < BusinessRuleViolation
      attr_reader :max_count

      def initialize(max_count)
        @max_count = max_count
        super("1回の予約は#{max_count}人までです")
      end
    end

    def initialize(max_count:, refund_hours_before_start:)
      unless max_count.between?(ReservationCount::MIN, ReservationCount::MAX)
        raise ArgumentError, "1回の予約の上限は#{ReservationCount::MIN}〜#{ReservationCount::MAX}人で決めてください"
      end

      super
    end

    DEFAULT = new(max_count: 4, refund_hours_before_start: CancellationDeadline::HOURS_BEFORE_START)

    def ensure_count_allowed!(count)
      raise TooManyAttendees, max_count if count.to_i > max_count
    end

    def cancellation_deadline(starts_at)
      CancellationDeadline.new(starts_at: starts_at, hours_before_start: refund_hours_before_start)
    end
  end
end
