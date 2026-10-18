require "domain_helper"

RSpec.describe Ticketing::ReservationCount do
  it "1〜10人で作れる（サービス全体の上限。主催者ごとの上限は ReservationPolicy）" do
    expect(described_class.new(1).value).to eq(1)
    expect(described_class.new(10).value).to eq(10)
  end

  it "0人や11人では作れない" do
    expect { described_class.new(0) }.to raise_error(ArgumentError, "人数は1〜10人で指定してください: 0")
    expect { described_class.new(11) }.to raise_error(ArgumentError, "人数は1〜10人で指定してください: 11")
  end

  it "整数でなければ作れない" do
    expect { described_class.new("2") }.to raise_error(ArgumentError)
  end
end
