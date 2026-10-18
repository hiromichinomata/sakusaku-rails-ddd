require "domain_helper"

RSpec.describe Ticketing::CancellationDeadline do
  let(:starts_at) { Time.new(2026, 11, 15, 10, 0, 0, "+09:00") }
  let(:deadline) { described_class.new(starts_at: starts_at) }

  it "返金期限は、開始時刻の72時間前" do
    expect(deadline.refund_until).to eq(Time.new(2026, 11, 12, 10, 0, 0, "+09:00"))
  end

  it "ちょうど72時間前は、返金する（R-09）" do
    expect(deadline.refundable_at?(deadline.refund_until)).to be(true)
  end

  it "72時間前を1秒でも過ぎたら、返金しない（R-09）" do
    expect(deadline.refundable_at?(deadline.refund_until + 1)).to be(false)
  end
end
