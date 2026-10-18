require "domain_helper"

RSpec.describe Ticketing::Lottery do
  def entry(id, count)
    Ticketing::Lottery::Entry.new(id: id, count: Ticketing::ReservationCount.new(count))
  end

  let(:entries) { [ entry(1, 2), entry(2, 3), entry(3, 1), entry(4, 2) ] }

  it "残席の範囲で、当選者を選ぶ。残りは落選（R-13）" do
    result = described_class.new(seats: 4).draw(entries, random: Random.new(1))

    expect(result.winners.sum { |e| e.count.to_i }).to be <= 4
    expect((result.winners + result.losers).map(&:id)).to match_array([ 1, 2, 3, 4 ])
  end

  it "同じ乱数の種なら、同じ結果になる（抽選をやり直して確かめられる）" do
    first = described_class.new(seats: 4).draw(entries, random: Random.new(42))
    again = described_class.new(seats: 4).draw(entries, random: Random.new(42))

    expect(again.winners.map(&:id)).to eq(first.winners.map(&:id))
  end

  it "入りきらない人数の申込は飛ばして、入る申込を当選にする" do
    result = described_class.new(seats: 1).draw([ entry(1, 3), entry(2, 1) ], random: Random.new(1))

    expect(result.winners.map(&:id)).to eq([ 2 ])
  end

  it "申込が残席より少なければ、全員当選" do
    result = described_class.new(seats: 10).draw(entries, random: Random.new(1))

    expect(result.losers).to be_empty
  end
end
