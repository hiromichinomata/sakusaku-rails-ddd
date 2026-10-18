require "rails_helper"

RSpec.describe Reservation do
  describe "データベースの二重予約の制約（R-03）" do
    let(:event) { create(:event) }

    before { create(:reservation, event: event, email: "hatsuka@example.com") }

    it "同じイベント・同じメールアドレスの有効な予約は、2件目を保存させない" do
      duplicate = build(:reservation, event: event, email: "hatsuka@example.com")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "キャンセル済みの予約とは重なってよい" do
      Reservation.last.update!(status: "canceled")
      again = build(:reservation, event: event, email: "hatsuka@example.com")

      expect(again.save(validate: false)).to be(true)
    end
  end
end
