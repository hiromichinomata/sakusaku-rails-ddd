require "domain_helper"

RSpec.describe Ticketing::DoubleBookingCheck do
  let(:email) { EmailAddress.new("hatsuka@example.com") }

  it "同じイベントに同じメールアドレスの有効な予約があれば、二重予約（R-03）" do
    reservations = double("予約のリポジトリ", active_exists?: true)

    expect { described_class.new(reservations).ensure_not_double_booked!(event_id: 1, email: email) }
      .to raise_error(Ticketing::Reservation::AlreadyReserved)
  end

  it "なければ何もしない" do
    reservations = double("予約のリポジトリ", active_exists?: false)

    expect { described_class.new(reservations).ensure_not_double_booked!(event_id: 1, email: email) }
      .not_to raise_error
  end
end
