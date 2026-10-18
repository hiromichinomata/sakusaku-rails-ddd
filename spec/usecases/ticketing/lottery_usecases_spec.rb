require "rails_helper"

RSpec.describe "抽選販売のユースケース" do
  let(:event) { create(:event, capacity: 4, price: 1500) }
  let(:inventories) { Ticketing::InventoryRepository.new }

  before { event.ticket_inventory.update!(sales_method: "lottery") }

  def enter(email, count)
    Ticketing::EnterLottery.new.call(event_id: event.id, name: "申込者", email: email, count: count)
  end

  describe Ticketing::EnterLottery do
    it "抽選に申し込める。申し込んだだけでは、席は押さえない" do
      enter("a@example.com", 2)

      expect(LotteryEntry.where(event_id: event.id).count).to eq(1)
      expect(inventories.find(event.id).reserved_count).to eq(0)
    end

    it "同じメールアドレスでは、1回だけ申し込める" do
      enter("a@example.com", 2)

      expect { enter("a@example.com", 1) }.to raise_error(Ticketing::EnterLottery::AlreadyEntered)
    end
  end

  it "抽選のイベントは、先着の申込を受け付けない" do
    expect { Ticketing::ReserveSeats.new.call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 1) }
      .to raise_error(Ticketing::Inventory::LotteryOnly, "このイベントは抽選です。抽選に申し込んでください")
  end

  describe Ticketing::DrawLottery do
    before do
      enter("a@example.com", 2)
      enter("b@example.com", 3)
      enter("c@example.com", 2)
    end

    it "当選者には仮予約を作って席を押さえ、落選者は落選にする" do
      result = described_class.new.call(event_id: event.id, random: Random.new(7))

      reserved = Reservation.where(event: event).sum(:quantity)
      expect(reserved).to be <= 4
      expect(inventories.find(event.id).reserved_count).to eq(reserved)
      expect(LotteryEntry.won.count).to eq(result.winners.size)
      expect(LotteryEntry.lost.count).to eq(result.losers.size)
      expect(LotteryEntry.won.pluck(:reservation_id)).to all(be_present)
    end

    it "当選者には、お支払いのお願いのメールが届く" do
      result = perform_enqueued_jobs { described_class.new.call(event_id: event.id, random: Random.new(7)) }

      expect(delivered_subjects.size).to eq(result.winners.size)
    end

    it "当選者の支払い期限は、抽選から24時間後（R-13）" do
      now = Time.current
      described_class.new.call(event_id: event.id, random: Random.new(7), now: now)

      Reservation.where(event: event).find_each do |reservation|
        expect(reservation.payment_deadline).to be_within(1.second).of(now + 24.hours)
      end
    end

    it "当選者の仮予約は、1時間たっても期限切れにならない" do
      described_class.new.call(event_id: event.id, random: Random.new(7))

      ExpirePendingReservationsJob.perform_now(now: 1.hour.from_now)

      expect(Reservation.pending.count).to eq(LotteryEntry.won.count)
    end

    it "抽選は1回だけ。2回目は、新しく当選も落選もしない" do
      described_class.new.call(event_id: event.id, random: Random.new(7))

      expect { described_class.new.call(event_id: event.id, random: Random.new(8)) }
        .not_to(change { Reservation.count })
    end
  end
end
