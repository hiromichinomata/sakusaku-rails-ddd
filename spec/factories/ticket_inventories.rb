FactoryBot.define do
  factory :ticket_inventory do
    event
    capacity { event.capacity }
    reserved_count { 0 }
  end
end
