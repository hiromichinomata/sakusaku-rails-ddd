FactoryBot.define do
  factory :organizer do
    name { "うめ公民館" }
    max_attendees_per_reservation { 4 }
    refund_hours_before_start { 72 }
  end
end
