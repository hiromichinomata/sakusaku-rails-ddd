module Ticketing
  # 抽選の申込（Lottery::Entry）を lottery_entries テーブルに保存し、読み込む
  class LotteryEntryRepository
    def add(event_id:, applicant:, count:)
      LotteryEntry.create!(event_id: event_id, name: applicant.name, email: applicant.email.to_s,
                           quantity: count.to_i)
    rescue ActiveRecord::RecordNotUnique
      raise EnterLottery::AlreadyEntered
    end

    # まだ抽選していない申込を、申し込んだ順に返す
    def entered_for(event_id)
      LotteryEntry.entered.where(event_id: event_id).order(:id).map do |record|
        Lottery::Entry.new(id: record.id, count: ReservationCount.new(record.quantity),
                           applicant: Applicant.new(name: record.name, email: record.email))
      end
    end

    def mark_won(entry, reservation_id:)
      LotteryEntry.where(id: entry.id).update_all(status: "won", reservation_id: reservation_id, updated_at: Time.current)
    end

    def mark_lost(entries)
      LotteryEntry.where(id: entries.map(&:id)).update_all(status: "lost", updated_at: Time.current)
    end
  end
end
