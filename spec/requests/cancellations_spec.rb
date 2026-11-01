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
      expect(Payment.find_by(reservation_id: reservation.id)).to be_refunded
      follow_redirect!
      expect(response.body).to include("キャンセルしました。6,000円を返金します。")
    end

    it "開催3日前を過ぎたら、キャンセルはできるが返金しない" do
      travel_to Time.zone.local(2026, 11, 13, 12, 0) do
        patch cancel_reservation_path(reservation)
      end

      expect(reservation.reload).to be_canceled
      expect(Payment.find_by(reservation_id: reservation.id)).to be_paid
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

        expect(Payment.find_by(reservation_id: reservation.id).refunded?).to eq(announced_refund)
      end
    end
  end

  describe "GET /reservations/:id" do
    it "返金の案内は、主催者が決めた返金期限を示す" do
      event.update!(organizer: create(:organizer, refund_hours_before_start: 24))

      travel_to Time.zone.local(2026, 11, 13, 12, 0) do
        get reservation_path(reservation)
      end

      expect(response.body).to include("全額を返金します（返金期限：2026年11月14日 10:00まで）")
      expect(response.body).not_to include("3日前")
    end

    it "返金期限を過ぎたら、その期限を示して返金しないと伝える" do
      travel_to Time.zone.local(2026, 11, 13, 12, 0) do
        get reservation_path(reservation)
      end

      expect(response.body).to include("返金期限（2026年11月12日 10:00）を過ぎたため、キャンセルしても返金はありません。")
    end
  end
end
