require "rails_helper"

RSpec.describe "お支払い", type: :request do
  let(:event) { create(:event, price: 1500) }
  let(:reservation) { create(:reservation, event: event, quantity: 2) }

  describe "POST /reservations/:reservation_id/payment" do
    it "支払いが成功すると、予約が確定して確定メールを送る" do
      expect { post reservation_payment_path(reservation), params: { token: "tok_visa" } }
        .to have_enqueued_mail(ReservationMailer, :confirmed)

      expect(reservation.reload).to be_confirmed
      expect(reservation.payment.amount).to eq(3000)
      expect(response).to redirect_to(reservation_path(reservation))
    end

    it "カードが使えなければ、仮予約のまま" do
      post reservation_payment_path(reservation), params: { token: "tok_declined" }

      expect(reservation.reload).to be_pending
      follow_redirect!
      expect(response.body).to include("カードが利用できませんでした")
    end

    it "予約から15分を過ぎると、支払えずに期限切れになる" do
      reservation.update!(created_at: 16.minutes.ago)

      post reservation_payment_path(reservation), params: { token: "tok_visa" }

      expect(reservation.reload).to be_expired
      expect(reservation.payment).to be_nil
    end
  end
end
