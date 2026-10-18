module Ticketing
  # イベント管理（上流）のイベントを、予約のコンテキストの言葉（SalesInfo）に読み替える
  class SalesInfoReader
    def find(event_id)
      event = ::Event.find(event_id)
      SalesInfo.new(event_id: event.id, price: Money.new(event.price),
                    sales_period: SalesPeriod.new(ends_at: event.starts_at),
                    cancellation_deadline: CancellationDeadline.new(starts_at: event.starts_at))
    rescue ActiveRecord::RecordNotFound
      raise NotFound, "イベント #{event_id} が見つかりません"
    end
  end
end
