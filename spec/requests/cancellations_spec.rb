require "rails_helper"

RSpec.describe "キャンセル", type: :request do
  let(:event) { create(:event, capacity: 4, price: 1500, starts_at: Time.zone.local(2026, 11, 15, 10, 0)) }
  let(:reservation) { create(:reservation, event: event, quantity: 4) }

  before do
    travel_to Time.zone.local(2026, 11, 1, 12, 0) do
      post reservation_payment_path(reservation), params: { token: "tok_visa" }
    end
  end

  describe "PATCH /reservations/:id/cancel" do
    it "開催3日前より前なら、キャンセルして全額返金する" do
      travel_to Time.zone.local(2026, 11, 10, 12, 0) do
        perform_enqueued_jobs { patch cancel_reservation_path(reservation) }
      end

      expect(reservation.reload).to be_canceled
      expect(reservation.payment).to be_refunded
      follow_redirect!
      expect(response.body).to include("キャンセルしました。6,000円を返金します。")
    end

    it "返金は、支払った金額で決済サービスに依頼する" do
      gateway = Billing::FakePaymentGateway.new
      allow(Billing).to receive(:gateway).and_return(gateway)
      expect(gateway).to receive(:refund)
        .with(charge_id: reservation.payment.charge_id, amount: Money.new(6000),
              idempotency_key: "refund-reservation-#{reservation.id}")
        .and_call_original

      travel_to Time.zone.local(2026, 11, 10, 12, 0) do
        perform_enqueued_jobs { patch cancel_reservation_path(reservation) }
      end
    end

    it "開催3日前を過ぎたら、キャンセルはできるが返金しない" do
      travel_to Time.zone.local(2026, 11, 13, 12, 0) do
        patch cancel_reservation_path(reservation)
      end

      expect(reservation.reload).to be_canceled
      expect(reservation.payment).to be_paid
    end

    it "キャンセルすると、残席に席が戻る" do
      event.ticket_inventory.update!(reserved_count: 4)

      travel_to Time.zone.local(2026, 11, 10, 12, 0) do
        patch cancel_reservation_path(reservation)
      end

      expect(Ticketing::InventoryRepository.new.find(event.id).remaining_seats).to eq(4)
    end

    it "キャンセルすると、その席にほかの人が予約できる" do
      travel_to Time.zone.local(2026, 11, 10, 12, 0) do
        patch cancel_reservation_path(reservation)
        post event_reservations_path(event),
             params: { reservation: { name: "マリゴールド", email: "marigold@example.com", quantity: 4 } }
      end

      expect(event.reservations.active.count).to eq(1)
    end

    it "ちょうど開催3日前は、画面の案内と実際の返金が一致する" do
      travel_to Time.zone.local(2026, 11, 12, 10, 0) do
        get reservation_path(reservation)
        announced_refund = response.body.include?("全額を返金します")

        perform_enqueued_jobs { patch cancel_reservation_path(reservation) }

        expect(reservation.reload.payment.refunded?).to eq(announced_refund)
      end
    end
  end
end
