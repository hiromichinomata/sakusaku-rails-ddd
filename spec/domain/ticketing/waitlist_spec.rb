require "domain_helper"

RSpec.describe Ticketing::Waitlist do
  def entry(id, count)
    Ticketing::Waitlist::Entry.new(id: id, count: Ticketing::ReservationCount.new(count))
  end

  it "空いた席に、登録の古い順から案内する（R-14）" do
    waitlist = described_class.new([ entry(1, 2), entry(2, 1), entry(3, 1) ])

    expect(waitlist.offers_for(3).map(&:id)).to eq([ 1, 2 ])
  end

  it "入りきらない人数の登録は飛ばして、次の人に案内する" do
    waitlist = described_class.new([ entry(1, 3), entry(2, 1) ])

    expect(waitlist.offers_for(2).map(&:id)).to eq([ 2 ])
  end

  it "席が空いていなければ、誰にも案内しない" do
    expect(described_class.new([ entry(1, 1) ]).offers_for(0)).to eq([])
  end
end
