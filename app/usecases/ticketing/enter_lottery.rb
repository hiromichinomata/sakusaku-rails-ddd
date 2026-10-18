module Ticketing
  # 抽選の申込。申し込んだだけでは、席は押さえない（R-13）
  class EnterLottery
    class AlreadyEntered < BusinessRuleViolation
      def initialize
        super("このメールアドレスでは、すでに抽選に申し込んでいます")
      end
    end

    def initialize(entries: LotteryEntryRepository.new, inventories: InventoryRepository.new,
                   sales_infos: SalesInfoReader.new)
      @entries = entries
      @inventories = inventories
      @sales_infos = sales_infos
    end

    def call(event_id:, name:, email:, count:, now: Time.current)
      applicant = Applicant.new(name: name, email: email)
      count = ReservationCount.new(count)
      sales_info = @sales_infos.find(event_id)
      sales_info.sales_period.ensure_open!(now)
      sales_info.policy.ensure_count_allowed!(count)
      raise ArgumentError, "抽選のイベントではありません" unless @inventories.find(event_id).lottery?

      @entries.add(event_id: event_id, applicant: applicant, count: count)
    end
  end
end
