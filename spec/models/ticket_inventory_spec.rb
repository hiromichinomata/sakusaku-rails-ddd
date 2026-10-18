require "rails_helper"

RSpec.describe TicketInventory do
  it "予約済みの人数が定員を超える行は、データベースが保存させない" do
    inventory = create(:ticket_inventory, capacity: 4, reserved_count: 4)

    expect { inventory.update!(reserved_count: 5) }.to raise_error(ActiveRecord::CheckViolation)
  end

  it "1つのイベントに、残席は1つだけ" do
    inventory = create(:ticket_inventory)

    expect { create(:ticket_inventory, event: inventory.event) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
