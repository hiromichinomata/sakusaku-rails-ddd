FactoryBot.define do
  factory :event do
    title { "梅酒づくりワークショップ" }
    description { "青梅と氷砂糖で、自分だけの梅酒を仕込みます。" }
    venue { "うめ公民館" }
    starts_at { Time.zone.local(2026, 11, 15, 10, 0) }
    capacity { 20 }
    price { 1500 }
  end
end
