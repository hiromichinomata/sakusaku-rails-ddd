FactoryBot.define do
  factory :event do
    title { "梅酒づくりワークショップ" }
    description { "青梅と氷砂糖で、自分だけの梅酒を仕込みます。" }
    venue { "うめ公民館" }
    starts_at { Time.zone.local(2026, 11, 15, 10, 0) }
    capacity { 20 }
    price { 1500 }

    transient do
      with_inventory { true }
    end

    # イベントを作ったら、予約のコンテキストの残席も作る（EventsController#create と同じ）
    after(:create) do |event, context|
      TicketInventory.create!(event: event, capacity: event.capacity) if context.with_inventory
    end
  end
end
