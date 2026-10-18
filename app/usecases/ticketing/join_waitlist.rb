module Ticketing
  # キャンセル待ちに登録する。満席（残席が申込の人数より少ない）のときだけ（R-14）
  class JoinWaitlist
    class SeatsAvailable < BusinessRuleViolation
      def initialize
        super("席が空いています。キャンセル待ちではなく、そのまま申し込んでください")
      end
    end

    def initialize(entries: WaitlistEntryRepository.new, inventories: InventoryRepository.new)
      @entries = entries
      @inventories = inventories
    end

    def call(event_id:, name:, email:, count:)
      applicant = Applicant.new(name: name, email: email)
      count = ReservationCount.new(count)
      inventory = @inventories.find(event_id)
      inventory.ensure_first_come!
      raise SeatsAvailable if count.to_i <= inventory.remaining_seats

      @entries.add(event_id: event_id, applicant: applicant, count: count)
    end
  end
end
