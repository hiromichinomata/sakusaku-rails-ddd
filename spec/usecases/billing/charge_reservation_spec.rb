require "rails_helper"

RSpec.describe Billing::ChargeReservation do
  let(:gateway) { Billing::FakePaymentGateway.new }
  let(:usecase) { described_class.new(gateway: gateway) }
  let(:reservation) { create(:reservation, quantity: 2) }

  it "支払い金額を受け取り、決済の記録を残す" do
    charge_id = usecase.call(reservation_id: reservation.id, amount: Money.new(3000), token: "tok_visa")

    expect(Payment.find_by!(reservation_id: reservation.id)).to have_attributes(amount: 3000, charge_id: charge_id)
  end

  it "同じ予約の支払いが記録済みなら、決済サービスを呼ばずに同じ支払いIDを返す" do
    allow(gateway).to receive(:charge).and_call_original
    first = usecase.call(reservation_id: reservation.id, amount: Money.new(3000), token: "tok_visa")

    second = usecase.call(reservation_id: reservation.id, amount: Money.new(3000), token: "tok_visa")

    expect(second).to eq(first)
    expect(gateway).to have_received(:charge).once
  end
end
