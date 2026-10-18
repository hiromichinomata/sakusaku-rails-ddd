require "rails_helper"

RSpec.describe "予約のライフサイクルのユースケース" do
  let(:event) { create(:event, capacity: 4, price: 1500) }
  let(:inventories) { Ticketing::InventoryRepository.new }
  let!(:reservation) do
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 3)
  end

  describe Ticketing::ConfirmReservation do
    it "仮予約を予約確定にする" do
      confirmed = described_class.new.call(reservation_id: reservation.id)

      expect(confirmed.status).to eq(:confirmed)
      expect(Ticketing::ReservationRepository.new.find(reservation.id).status).to eq(:confirmed)
    end
  end

  describe Ticketing::ExpireReservation do
    it "支払い期限を過ぎた仮予約を期限切れにして、席を戻す" do
      described_class.new.call(reservation_id: reservation.id, now: reservation.payment_deadline + 1)

      expect(Ticketing::ReservationRepository.new.find(reservation.id).status).to eq(:expired)
      expect(inventories.find(event.id).reserved_count).to eq(0)
    end

    it "支払い期限の前なら、期限切れにせず、席もそのまま" do
      expect { described_class.new.call(reservation_id: reservation.id, now: reservation.payment_deadline) }
        .to raise_error(Ticketing::Reservation::InvalidTransition)

      expect(inventories.find(event.id).reserved_count).to eq(3)
    end
  end

  describe Ticketing::CancelReservation do
    it "予約をキャンセル済みにして、席を戻す" do
      described_class.new.call(reservation_id: reservation.id)

      expect(Ticketing::ReservationRepository.new.find(reservation.id).status).to eq(:canceled)
      expect(inventories.find(event.id).reserved_count).to eq(0)
    end

    it "主催者が返金期限を24時間前と決めたイベントは、48時間前のキャンセルでも返金する" do
      event.update!(organizer: create(:organizer, refund_hours_before_start: 24))
      Ticketing::PayForReservation.new.call(reservation_id: reservation.id, token: "tok_visa")

      result = described_class.new.call(reservation_id: reservation.id, now: event.starts_at - 48.hours)

      expect(result.refund_amount).to eq(Money.new(4500))
    end

    it "2回キャンセルしても、席は2回戻らない" do
      described_class.new.call(reservation_id: reservation.id)

      expect { described_class.new.call(reservation_id: reservation.id) }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "キャンセル済みの予約は、キャンセルできません")
      expect(inventories.find(event.id).reserved_count).to eq(0)
    end
  end
end
