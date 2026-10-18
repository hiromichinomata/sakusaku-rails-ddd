require "domain_helper"

RSpec.describe Ticketing::Inventory do
  def count(value) = Ticketing::ReservationCount.new(value)

  let(:inventory) { described_class.new(event_id: 1, capacity: 20, reserved_count: 18) }

  it "残席は、定員 − 予約済みの人数" do
    expect(inventory.remaining_seats).to eq(2)
  end

  describe "#reserve" do
    it "残席の範囲なら、予約済みの人数が増える" do
      inventory.reserve(count(2))

      expect(inventory.reserved_count).to eq(20)
      expect(inventory.remaining_seats).to eq(0)
    end

    it "残席を超える人数は予約できず、予約済みの人数も変わらない" do
      expect { inventory.reserve(count(3)) }
        .to raise_error(Ticketing::Inventory::NotEnoughSeats, "残りの席数（2席）を超えています")

      expect(inventory.reserved_count).to eq(18)
    end
  end

  describe "#release" do
    it "キャンセルや期限切れで、席を戻す" do
      inventory.release(count(4))

      expect(inventory.reserved_count).to eq(14)
    end
  end

  describe "#change_capacity" do
    it "予約済みの人数ちょうどまでは減らせる（R-11）" do
      inventory.change_capacity(18)

      expect(inventory.capacity).to eq(18)
    end

    it "予約済みの人数より少なくはできない（R-11）" do
      expect { inventory.change_capacity(17) }
        .to raise_error(Ticketing::Inventory::CapacityBelowReserved, "定員は予約済みの人数（18人）より少なくできません")
    end
  end

  it "予約済みの人数が定員を超えた残席は作れない" do
    expect { described_class.new(event_id: 1, capacity: 20, reserved_count: 21) }.to raise_error(ArgumentError)
  end
end
