FactoryBot.define do
  factory :reservation do
    event
    name { "初花" }
    sequence(:email) { |n| "attendee#{n}@example.com" }
    quantity { 1 }
    price { event.price } # 申し込んだときの料金（R-12）
    payment_due_at { (created_at || Time.current) + Ticketing::Reservation::PAYMENT_WINDOW }
  end
end
