require "rails_helper"

RSpec.describe "キャンセル待ちのユースケース" do
  let(:event) { create(:event, capacity: 2, price: 1500) }
  let(:inventories) { Ticketing::InventoryRepository.new }
  let!(:first) do
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "先客", email: "first@example.com", count: 2) # 満席
  end

  def join(email, count)
    Ticketing::JoinWaitlist.new.call(event_id: event.id, name: "待っている人", email: email, count: count)
  end

  describe Ticketing::JoinWaitlist do
    it "満席なら、キャンセル待ちに登録できる" do
      join("b@example.com", 1)

      expect(WaitlistEntry.waiting.where(event_id: event.id).count).to eq(1)
    end

    it "席が空いていれば、キャンセル待ちではなく、そのまま申し込んでもらう" do
      Ticketing::CancelReservation.new.call(reservation_id: first.id)

      expect { join("b@example.com", 1) }.to raise_error(Ticketing::JoinWaitlist::SeatsAvailable)
    end
  end

  it "キャンセルが出ると、登録の古い順に、入る人数の人へ仮予約を作る（R-14）" do
    join("b@example.com", 1)
    join("c@example.com", 2)

    perform_enqueued_jobs { Ticketing::CancelReservation.new.call(reservation_id: first.id) }

    offered = WaitlistEntry.find_by!(email: "b@example.com")
    expect(offered).to be_offered
    expect(Reservation.find(offered.reservation_id)).to be_pending
    expect(WaitlistEntry.find_by!(email: "c@example.com")).to be_waiting # 残り1席には入らない
    expect(inventories.find(event.id).reserved_count).to eq(1)
    expect(delivered_subjects).to include("【うめチケット】お支払いのお願い：梅酒づくりワークショップ")
  end

  it "すでに有効な予約がある人は飛ばす" do
    join("b@example.com", 1)
    Ticketing::CancelReservation.new.call(reservation_id: first.id)
    Ticketing::ReserveSeats.new.call(event_id: event.id, name: "待っている人", email: "b@example.com", count: 1)

    Ticketing::OfferReleasedSeats.new.call(event_id: event.id)

    expect(WaitlistEntry.find_by!(email: "b@example.com")).to be_skipped
  end
end
