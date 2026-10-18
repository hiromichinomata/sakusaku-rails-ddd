require "rails_helper"

RSpec.describe Ticketing::InventoryConsistencyCheck do
  let(:event) { create(:event, capacity: 4) }

  before do
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 2)
  end

  it "ユースケースだけで変えていれば、ずれはない" do
    expect(described_class.new.call).to eq([])
  end

  it "予約の状態を直接書き換えると、ずれとして見つかる" do
    Reservation.last.update_columns(status: "canceled") # コンソールでうっかり書き換えた

    expect(described_class.new.call).to eq(
      [ Ticketing::InventoryConsistencyCheck::Mismatch.new(event_id: event.id, recorded: 2, actual: 0) ]
    )
  end
end
