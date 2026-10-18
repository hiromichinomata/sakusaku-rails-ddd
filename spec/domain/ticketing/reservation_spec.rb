require "domain_helper"

RSpec.describe Ticketing::Reservation do
  def build(id: nil, count: 2)
    described_class.new(
      id: id,
      event_id: 1,
      applicant: Ticketing::Applicant.new(name: "初花", email: "hatsuka@example.com"),
      count: Ticketing::ReservationCount.new(count),
      price: Money.new(1500)
    )
  end

  describe "同一性" do
    it "IDが同じなら、人数が違っても同じ予約" do
      expect(build(id: 1, count: 2)).to eq(build(id: 1, count: 3))
    end

    it "IDが違えば、中身が同じでも別の予約" do
      expect(build(id: 1)).not_to eq(build(id: 2))
    end

    it "まだIDのない予約どうしは、同じオブジェクトでなければ別の予約" do
      reservation = build

      expect(reservation).to eq(reservation)
      expect(build).not_to eq(build)
    end
  end

  it "支払い金額は、料金 × 人数" do
    expect(build(count: 2).total_price).to eq(Money.new(3000))
  end

  describe ".apply" do
    def apply(price)
      described_class.apply(event_id: 1, applicant: Ticketing::Applicant.new(name: "初花", email: "hatsuka@example.com"),
                            count: Ticketing::ReservationCount.new(2), price: Money.new(price),
                            reserved_at: Time.new(2026, 11, 1, 10, 0, 0, "+09:00"))
    end

    it "有料のイベントの申込は、仮予約になる（R-05）" do
      expect(apply(1500).status).to eq(:pending)
    end

    it "無料のイベントの申込は、予約確定になる（R-06）" do
      expect(apply(0).status).to eq(:confirmed)
    end
  end

  it "人数は1〜10人の範囲でしか作れない" do
    expect { build(count: 11) }.to raise_error(ArgumentError)
  end
end
