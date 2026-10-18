require "domain_helper"

RSpec.describe Ticketing::SalesPeriod do
  let(:starts_at) { Time.new(2026, 11, 15, 10, 0, 0, "+09:00") }
  let(:period) { described_class.new(ends_at: starts_at) }

  it "開始時刻の1秒前は受け付けている" do
    expect(period.open_at?(starts_at - 1)).to be(true)
  end

  it "開始時刻ちょうどからは受け付けない（R-04）" do
    expect(period.open_at?(starts_at)).to be(false)
    expect { period.ensure_open!(starts_at) }
      .to raise_error(Ticketing::SalesPeriod::Closed, "このイベントの受付は終了しました")
  end
end
