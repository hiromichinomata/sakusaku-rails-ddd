require "rails_helper"

RSpec.describe "お支払い", type: :request do
  let(:event) { create(:event, price: 1500) }
  let(:reservation) { create(:reservation, event: event, quantity: 2) }

  describe "POST /reservations/:reservation_id/payment" do
    it "支払いが成功すると、予約が確定して確定メールを送る" do
      perform_enqueued_jobs { post reservation_payment_path(reservation), params: { token: "tok_visa" } }

      expect(delivered_subjects).to eq([ "【うめチケット】予約が確定しました：梅酒づくりワークショップ" ])

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

    it "決済サービスにつながらなければ、もう一度試すよう案内する" do
      gateway = Billing::FakePaymentGateway.new
      allow(gateway).to receive(:charge).and_raise(Billing::GatewayUnavailable)
      allow(Billing).to receive(:gateway).and_return(gateway)

      post reservation_payment_path(reservation), params: { token: "tok_visa" }

      expect(reservation.reload).to be_pending
      follow_redirect!
      expect(response.body).to include("決済サービスにつながりませんでした。時間をおいて、もう一度お試しください。")
    end

    it "支払いのボタンを2回押しても、受け取るのは1回だけ" do
      2.times { post reservation_payment_path(reservation), params: { token: "tok_visa" } }

      expect(Payment.where(reservation: reservation).count).to eq(1)
      follow_redirect!
      expect(response.body).to include("お支払いはすでに完了しています。")
    end

    it "予約から15分を過ぎると、支払えずに期限切れになる" do
      reservation.update!(created_at: 16.minutes.ago)

      post reservation_payment_path(reservation), params: { token: "tok_visa" }

      expect(reservation.reload).to be_expired
      expect(reservation.payment).to be_nil
    end
  end
end
