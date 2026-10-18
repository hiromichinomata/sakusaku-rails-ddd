require "rails_helper"

RSpec.describe TicketInventory do
  it "予約済みの人数が定員を超える行は、データベースが保存させない" do
    inventory = create(:event, capacity: 4).ticket_inventory
    inventory.update!(reserved_count: 4)

    expect { inventory.update!(reserved_count: 5) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "1つのイベントに、残席は1つだけ" do
    event = create(:event)

    expect { TicketInventory.create!(event: event, capacity: 20) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
