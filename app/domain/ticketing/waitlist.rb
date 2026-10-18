module Ticketing
  # キャンセル待ち。空いた席に、登録の古い順から、入る人数の人を案内する（R-14）
  class Waitlist
    class Entry < Data.define(:id, :count, :applicant)
      def initialize(id:, count:, applicant: nil)
        super
      end
    end

    # entries は登録の古い順
    def initialize(entries)
      @entries = entries
    end

    def offers_for(seats)
      remaining = seats
      @entries.select do |entry|
        next false if entry.count.to_i > remaining

        remaining -= entry.count.to_i
        true
      end
    end
  end
end
