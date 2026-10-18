require "domain_helper"

RSpec.describe Ticketing::ReservationCount do
  it "1〜4人で作れる" do
    expect(described_class.new(1).value).to eq(1)
    expect(described_class.new(4).value).to eq(4)
  end

  it "0人や5人では作れない" do
    expect { described_class.new(0) }.to raise_error(ArgumentError, "人数は1〜4人で指定してください: 0")
    expect { described_class.new(5) }.to raise_error(ArgumentError, "人数は1〜4人で指定してください: 5")
  end

  it "整数でなければ作れない" do
    expect { described_class.new("2") }.to raise_error(ArgumentError)
  end
end
