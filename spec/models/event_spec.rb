require "rails_helper"

RSpec.describe Event do
  describe "定員の変更" do
    let(:event) { create(:event, capacity: 20) }

    before { create(:reservation, event: event, quantity: 4) }

    it "予約済みの人数より少なくはできない" do
      event.capacity = 3

      expect(event).not_to be_valid
      expect(event.errors.full_messages).to include("定員は予約済みの人数（4人）より少なくできません")
    end

    it "予約済みの人数ちょうどまでは減らせる" do
      event.capacity = 4

      expect(event).to be_valid
    end
  end
end
