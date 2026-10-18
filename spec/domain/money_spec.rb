require "domain_helper"

RSpec.describe Money do
  describe "作るとき" do
    it "0以上の整数（円）で作れる" do
      expect(Money.new(1500).yen).to eq(1500)
      expect(Money.new(0)).to be_zero
    end

    it "負の数は金額にならない" do
      expect { Money.new(-100) }.to raise_error(ArgumentError, "金額は0以上の整数（円）で指定してください: -100")
    end

    it "文字列や小数は金額にならない" do
      expect { Money.new("1500") }.to raise_error(ArgumentError)
      expect { Money.new(1500.5) }.to raise_error(ArgumentError)
    end
  end

  describe "計算" do
    it "足し算は金額どうしでする" do
      expect(Money.new(1500) + Money.new(500)).to eq(Money.new(2000))
    end

    it "掛け算は整数とする" do
      expect(Money.new(1500) * 2).to eq(Money.new(3000))
      expect { Money.new(1500) * 2.5 }.to raise_error(ArgumentError)
    end

    it "大きさを比べられる" do
      expect(Money.new(1500)).to be > Money.new(1000)
    end
  end

  it "3桁区切りと「円」を付けて表示する" do
    expect(Money.new(1_234_567).to_s).to eq("1,234,567円")
  end
end
