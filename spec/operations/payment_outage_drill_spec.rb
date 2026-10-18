require "rails_helper"

# 運用演習：うめペイが止まっている間にキャンセルが来て、直ったあとに返金をやり直す（docs/runbook.md）
RSpec.describe "決済サービスの障害の演習" do
  let(:event) { create(:event, price: 1500, starts_at: Time.zone.local(2026, 11, 15, 10, 0)) }
  let(:gateway) { Billing::FakePaymentGateway.new }
  let(:reservation) do
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 2)
  end
  let(:payment) { Payment.find_by!(reservation_id: reservation.id) }

  before do
    allow(Billing).to receive(:gateway).and_return(gateway)
    Ticketing::PayForReservation.new.call(reservation_id: reservation.id, token: "tok_visa")
  end

  it "止まっている間のキャンセルは返金に失敗し、直ったあとに積み直すと返金される" do
    # 1. うめペイが止まる
    allow(gateway).to receive(:refund).and_raise(Billing::GatewayUnavailable, "うめペイにつながりませんでした")

    # 2. その間にキャンセルが来る。返金のジョブは5回やり直して、失敗として記録される
    perform_enqueued_jobs { Ticketing::CancelReservation.new.call(reservation_id: reservation.id) }
    expect(payment.reload).to be_refund_failed

    # 3. 運用の担当者が、失敗した返金を見つける
    expect(Payment.refund_failed.pluck(:reservation_id)).to eq([ reservation.id ])

    # 4. うめペイが直ったあと、積み直す
    allow(gateway).to receive(:refund).and_call_original
    perform_enqueued_jobs { Billing::RetryFailedRefunds.new.call }

    expect(payment.reload).to be_refunded
  end
end
