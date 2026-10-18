require "rails_helper"

RSpec.describe ExpirePendingReservationsJob do
  it "支払い期限を過ぎた仮予約を、期限切れにする" do
    old = create(:reservation, created_at: 16.minutes.ago)
    fresh = create(:reservation, created_at: 1.minute.ago)

    described_class.perform_now

    expect(old.reload).to be_expired
    expect(fresh.reload).to be_pending
  end

  it "期限切れにした予約の席を、残席に戻す" do
    reservation = create(:reservation, quantity: 3, created_at: 16.minutes.ago)
    reservation.event.ticket_inventory.update!(reserved_count: 3)

    described_class.perform_now

    expect(Ticketing::InventoryRepository.new.find(reservation.event_id).reserved_count).to eq(0)
  end
end
