require "rails_helper"

RSpec.describe Ticketing::InventoryRepository do
  let(:repository) { described_class.new }
  let(:event) { create(:event, capacity: 20, with_inventory: false) }

  it "残席を保存して、読み込める" do
    repository.add(Ticketing::Inventory.new(event_id: event.id, capacity: 20))

    inventory = repository.find(event.id)

    expect(inventory).to be_a(Ticketing::Inventory)
    expect(inventory.remaining_seats).to eq(20)
  end

  it "変えた残席を保存すると、次に読み込んだときに反映されている" do
    repository.add(Ticketing::Inventory.new(event_id: event.id, capacity: 20))
    inventory = repository.find(event.id)

    inventory.reserve(Ticketing::ReservationCount.new(3))
    repository.save(inventory)

    expect(repository.find(event.id).reserved_count).to eq(3)
  end

  it "残席がなければ Ticketing::NotFound" do
    expect { repository.find(event.id) }.to raise_error(Ticketing::NotFound)
  end
end
