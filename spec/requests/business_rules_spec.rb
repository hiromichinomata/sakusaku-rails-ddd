require "rails_helper"

# docs/domain/rules.md の「〜まで」「ちょうど」の解釈を、境界の時刻で確かめる
RSpec.describe "業務ルールの境界", type: :request do
  let(:starts_at) { Time.zone.local(2026, 11, 15, 10, 0) }
  let(:event) { create(:event, price: 1500, starts_at: starts_at) }

  def reserve
    post event_reservations_path(event),
         params: { reservation: { name: "初花", email: "hatsuka@example.com", quantity: 1 } }
  end

  def pay(reservation)
    post reservation_payment_path(reservation), params: { token: "tok_visa" }
  end

  describe "R-04 申込は開始時刻の前まで" do
    it "開始時刻の1分前は申し込める" do
      travel_to(starts_at - 1.minute) { expect { reserve }.to change(Reservation, :count).by(1) }
    end

    it "開始時刻ちょうどは申し込めない" do
      travel_to(starts_at) { expect { reserve }.not_to change(Reservation, :count) }
    end
  end

  describe "R-05 支払いは仮予約から15分後まで（ちょうどを含む）" do
    let(:reservation) { create(:reservation, event: event, created_at: Time.current) }

    it "ちょうど15分後は支払える" do
      travel_to(reservation.created_at + 15.minutes) { pay(reservation) }

      expect(reservation.reload).to be_confirmed
    end

    it "15分1秒後は支払えない" do
      travel_to(reservation.created_at + 15.minutes + 1.second) { pay(reservation) }

      expect(reservation.reload).to be_expired
    end
  end

  describe "R-07 支払い期限を過ぎた仮予約は期限切れ" do
    let!(:reservation) { create(:reservation, event: event, created_at: Time.current) }

    it "ちょうど15分後は、まだ期限切れにしない" do
      travel_to(reservation.created_at + 15.minutes) { ExpirePendingReservationsJob.perform_now }

      expect(reservation.reload).to be_pending
    end
  end

  describe "R-09 返金は開始時刻の72時間前まで（ちょうどを含む）" do
    let(:reservation) { create(:reservation, event: event, quantity: 2) }

    before { pay(reservation) }

    it "ちょうど72時間前のキャンセルは、全額返金する" do
      pending "コントローラが「72時間前より前」で比べている（第14章で直す）"
      travel_to(starts_at - 72.hours) { patch cancel_reservation_path(reservation) }

      expect(reservation.reload.payment).to be_refunded
    end

    it "72時間前を1分過ぎたキャンセルは、返金しない" do
      travel_to(starts_at - 72.hours + 1.minute) { patch cancel_reservation_path(reservation) }

      expect(reservation.reload.payment).to be_paid
    end
  end

  describe "R-10 キャンセル済みは予約確定に戻せない" do
    it "キャンセル済みの予約を確定に書き換えられない" do
      pending "状態を自由に書き換えられる（第14章で直す）"
      reservation = create(:reservation, event: event, status: "canceled")

      expect(reservation.update(status: "confirmed")).to be(false)
    end
  end
end
