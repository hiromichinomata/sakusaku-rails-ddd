require "domain_helper"

RSpec.describe Ticketing::Reservation do
  def build(id: nil, count: 2)
    described_class.new(id: id, event_id: 1, name: "初花", email: "hatsuka@example.com",
                        count: count, price: 1500)
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
    expect(build(count: 2).total_price).to eq(3000)
  end
end
