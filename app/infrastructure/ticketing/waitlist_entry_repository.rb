module Ticketing
  # キャンセル待ち（Waitlist::Entry）を waitlist_entries テーブルに保存し、読み込む
  class WaitlistEntryRepository
    def add(event_id:, applicant:, count:)
      WaitlistEntry.create!(event_id: event_id, name: applicant.name, email: applicant.email.to_s,
                            quantity: count.to_i)
    end

    # 待っている登録を、登録の古い順に返す
    def waiting_for(event_id)
      WaitlistEntry.waiting.where(event_id: event_id).order(:id).map do |record|
        Waitlist::Entry.new(id: record.id, count: ReservationCount.new(record.quantity),
                            applicant: Applicant.new(name: record.name, email: record.email))
      end
    end

    def mark_offered(entry, reservation_id:)
      WaitlistEntry.where(id: entry.id).update_all(status: "offered", reservation_id: reservation_id,
                                                   updated_at: Time.current)
    end

    def mark_skipped(entries)
      WaitlistEntry.where(id: entries.map(&:id)).update_all(status: "skipped", updated_at: Time.current)
    end
  end
end
