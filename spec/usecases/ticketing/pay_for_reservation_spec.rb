require "rails_helper"

RSpec.describe Ticketing::PayForReservation do
  let(:event) { create(:event, price: 1500) }
  let(:gateway) { Billing::FakePaymentGateway.new }
  let(:usecase) { described_class.new(gateway: gateway) }
  let!(:reservation) do
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 2)
  end

  def pay(token: "tok_visa", now: Time.current)
    usecase.call(reservation_id: reservation.id, token: token, now: now)
  end

  it "支払い金額を受け取って、予約確定にする" do
    result = pay

    expect(result.reservation.status).to eq(:confirmed)
    expect(Payment.find_by!(reservation_id: reservation.id).amount).to eq(3000)
  end

  it "支払いが2回届いても、受け取るのは1回だけ" do
    allow(gateway).to receive(:charge).and_call_original

    pay
    second = pay

    expect(second.already_paid).to be(true)
    expect(gateway).to have_received(:charge).once
    expect(Payment.where(reservation_id: reservation.id).count).to eq(1)
  end

  it "決済サービスにつながらなければ、何も記録せず、仮予約のまま" do
    allow(gateway).to receive(:charge).and_raise(Billing::GatewayUnavailable)

    expect { pay }.to raise_error(Billing::GatewayUnavailable)

    expect(Payment.count).to eq(0)
    expect(Ticketing::ReservationRepository.new.find(reservation.id).status).to eq(:pending)
  end

  it "支払い期限を過ぎていたら、決済サービスに頼まずに期限切れにする" do
    allow(gateway).to receive(:charge)

    expect { pay(now: reservation.payment_deadline + 1) }.to raise_error(Ticketing::Reservation::PaymentDeadlinePassed)

    expect(gateway).not_to have_received(:charge)
    expect(Ticketing::ReservationRepository.new.find(reservation.id).status).to eq(:expired)
  end
end
