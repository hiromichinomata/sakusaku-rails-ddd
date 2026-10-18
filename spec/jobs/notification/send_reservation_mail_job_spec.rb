require "rails_helper"

RSpec.describe Notification::SendReservationMailJob do
  it "予約のメールを送る" do
    reservation = create(:reservation, quantity: 2)

    described_class.perform_now(reservation.id, "payment_request")

    expect(delivered_subjects).to eq([ "【うめチケット】お支払いのお願い：梅酒づくりワークショップ" ])
  end

  it "予約が消えていたら、エラーにせず捨てる" do
    expect { described_class.perform_now(0, "payment_request") }.not_to raise_error

    expect(delivered_subjects).to be_empty
  end
end
