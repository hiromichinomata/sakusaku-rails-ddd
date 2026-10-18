module Ticketing
  # イベント管理（上流）のイベントを、予約のコンテキストの言葉（SalesInfo）に読み替える
  class SalesInfoReader
    def find(event_id)
      event = ::Event.includes(:organizer).find(event_id)
      policy = policy_for(event.organizer)
      SalesInfo.new(event_id: event.id, price: Money.new(event.price),
                    sales_period: SalesPeriod.new(ends_at: event.starts_at),
                    cancellation_deadline: policy.cancellation_deadline(event.starts_at), policy: policy)
    rescue ActiveRecord::RecordNotFound
      raise NotFound, "イベント #{event_id} が見つかりません"
    end

    private

    # 主催者が決めたルール。主催者のいないイベントは、既定のルール
    def policy_for(organizer)
      return ReservationPolicy::DEFAULT if organizer.nil?

      ReservationPolicy.new(max_count: organizer.max_attendees_per_reservation,
                            refund_hours_before_start: organizer.refund_hours_before_start)
    end
  end
end
