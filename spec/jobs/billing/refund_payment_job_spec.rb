require "rails_helper"

RSpec.describe Billing::RefundPaymentJob do
  let(:reservation) { create(:reservation, quantity: 2, status: "canceled") }
  let!(:payment) { Payment.create!(reservation: reservation, amount: 3000, charge_id: "ch_test") }

  it "決済サービスに返金を頼み、返金済みにする" do
    described_class.perform_now(reservation.id, 3000)

    expect(payment.reload).to be_refunded
    expect(payment.refund_id).to start_with("re_")
  end

  it "同じ返金のジョブが2回動いても、決済サービスには1回しか頼まない" do
    allow(Billing::PaymentGateway).to receive(:refund).and_call_original

    2.times { described_class.perform_now(reservation.id, 3000) }

    expect(Billing::PaymentGateway).to have_received(:refund).once
  end

  it "決済サービスにつながらなければ、やり直す" do
    unavailable = ->(**) { raise Billing::PaymentGateway::Unavailable }
    allow(Billing::PaymentGateway).to receive(:refund).and_invoke(unavailable, unavailable, ->(**) { "re_retry" })

    perform_enqueued_jobs { described_class.perform_later(reservation.id, 3000) }

    expect(Billing::PaymentGateway).to have_received(:refund).exactly(3).times
    expect(payment.reload.refund_id).to eq("re_retry")
  end

  it "5回やり直してもつながらなければ、返金に失敗したことを記録する" do
    allow(Billing::PaymentGateway).to receive(:refund).and_raise(Billing::PaymentGateway::Unavailable)

    perform_enqueued_jobs { described_class.perform_later(reservation.id, 3000) }

    expect(Billing::PaymentGateway).to have_received(:refund).exactly(5).times
    expect(payment.reload).to be_refund_failed
  end
end
