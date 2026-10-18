module Ticketing
  # 予約。ID で見分けるエンティティ。状態は、決まった遷移のメソッドでしか変えられない
  class Reservation
    # 同じイベントに、同じメールアドレスの有効な予約がすでにある（R-03）
    class AlreadyReserved < BusinessRuleViolation
      def initialize
        super("このメールアドレスでは、すでに予約があります")
      end
    end

    # 今の状態からは、その操作ができない
    class InvalidTransition < BusinessRuleViolation
      def initialize(state_name, action)
        super("#{state_name}の予約は、#{action}できません")
      end
    end

    class PaymentDeadlinePassed < BusinessRuleViolation
      def initialize
        super("支払い期限を過ぎています")
      end
    end

    STATUS_NAMES = { pending: "仮予約", confirmed: "予約確定", canceled: "キャンセル済み", expired: "期限切れ" }.freeze
    PAYMENT_WINDOW = 15 * 60 # 支払い期限は、ふつうは仮予約の作成から15分後（秒）

    attr_reader :id, :event_id, :applicant, :count, :price, :status, :reserved_at, :payment_deadline

    # 申込から、新しい予約を作る。有料なら仮予約（R-05）、無料なら予約確定（R-06）。
    # payment_window は、支払い期限までの時間（抽選の当選者は24時間。R-13）
    def self.apply(event_id:, applicant:, count:, price:, reserved_at:, payment_window: PAYMENT_WINDOW)
      new(event_id: event_id, applicant: applicant, count: count, price: price, reserved_at: reserved_at,
          payment_deadline: reserved_at + payment_window, status: price.zero? ? :confirmed : :pending)
    end

    def initialize(event_id:, applicant:, count:, price:, reserved_at: nil, payment_deadline: nil, id: nil,
                   status: :pending)
      @id = id
      @event_id = event_id
      @applicant = applicant
      @count = count
      @price = price
      @reserved_at = reserved_at
      @payment_deadline = payment_deadline || (reserved_at && reserved_at + PAYMENT_WINDOW)
      @status = status
    end

    def total_price
      price * count.to_i
    end

    def status_name
      STATUS_NAMES.fetch(status)
    end

    # 支払いを受け付けてよいか。決済サービスに頼む前に確かめる（R-05・R-10）
    def ensure_payable!(now:)
      raise InvalidTransition.new(status_name, "支払い") unless status == :pending
      raise PaymentDeadlinePassed if now > payment_deadline
    end

    # 支払いが済んだ（R-05・R-10）
    def confirm(now:)
      raise InvalidTransition.new(status_name, "確定") unless status == :pending
      raise PaymentDeadlinePassed if now > payment_deadline

      @status = :confirmed
    end

    # 申込者が取りやめた（R-08）
    def cancel
      raise InvalidTransition.new(status_name, "キャンセル") unless %i[pending confirmed].include?(status)

      @status = :canceled
    end

    # 支払い期限を過ぎた（R-07）
    def expire(now:)
      raise InvalidTransition.new(status_name, "期限切れに") unless status == :pending
      raise InvalidTransition.new("支払い期限の前", "期限切れに") if now <= payment_deadline

      @status = :expired
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
