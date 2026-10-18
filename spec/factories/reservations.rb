FactoryBot.define do
  factory :reservation do
    event
    name { "初花" }
    sequence(:email) { |n| "attendee#{n}@example.com" }
    quantity { 1 }
  end
end
