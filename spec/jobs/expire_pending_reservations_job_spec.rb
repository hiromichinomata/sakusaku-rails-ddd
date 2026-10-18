require "rails_helper"

RSpec.describe ExpirePendingReservationsJob do
  it "予約から15分を過ぎたお支払い待ちの予約を、期限切れにする" do
    old = create(:reservation, created_at: 16.minutes.ago)
    fresh = create(:reservation, created_at: 1.minute.ago)

    described_class.perform_now

    expect(old.reload).to be_expired
    expect(fresh.reload).to be_pending
  end
end
