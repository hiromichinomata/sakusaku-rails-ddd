require "domain_helper"

RSpec.describe Ticketing::Reservation, "の状態遷移" do
  let(:reserved_at) { Time.new(2026, 11, 1, 10, 0, 0, "+09:00") }

  def reservation(status)
    described_class.new(id: 1, event_id: 1, status: status, reserved_at: reserved_at,
                        applicant: Ticketing::Applicant.new(name: "初花", email: "hatsuka@example.com"),
                        count: Ticketing::ReservationCount.new(2), price: Money.new(1500))
  end

  it "支払い期限は、仮予約の作成から15分後" do
    expect(reservation(:pending).payment_deadline).to eq(reserved_at + (15 * 60))
  end

  describe "#confirm（支払いが済んだ）" do
    it "仮予約は、支払い期限ちょうどまでなら予約確定になる（R-05）" do
      target = reservation(:pending)

      target.confirm(now: target.payment_deadline)

      expect(target.status).to eq(:confirmed)
    end

    it "支払い期限を過ぎた仮予約は、確定できない" do
      target = reservation(:pending)

      expect { target.confirm(now: target.payment_deadline + 1) }
        .to raise_error(Ticketing::Reservation::PaymentDeadlinePassed, "支払い期限を過ぎています")
    end

    it "キャンセル済みは、予約確定に戻せない（R-10）" do
      expect { reservation(:canceled).confirm(now: reserved_at) }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "キャンセル済みの予約は、確定できません")
    end
  end

  describe "#cancel（申込者が取りやめた）" do
    it "仮予約と予約確定は、キャンセルできる（R-08）" do
      %i[pending confirmed].each do |status|
        target = reservation(status)
        target.cancel

        expect(target.status).to eq(:canceled)
      end
    end

    it "キャンセル済み・期限切れは、キャンセルできない（R-08）" do
      expect { reservation(:canceled).cancel }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "キャンセル済みの予約は、キャンセルできません")
      expect { reservation(:expired).cancel }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "期限切れの予約は、キャンセルできません")
    end
  end

  describe "#expire（支払い期限を過ぎた）" do
    it "支払い期限を過ぎた仮予約は、期限切れになる（R-07）" do
      target = reservation(:pending)

      target.expire(now: target.payment_deadline + 1)

      expect(target.status).to eq(:expired)
    end

    it "支払い期限ちょうどは、まだ期限切れにしない" do
      target = reservation(:pending)

      expect { target.expire(now: target.payment_deadline) }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "支払い期限の前の予約は、期限切れにできません")
    end

    it "予約確定は、期限切れにできない" do
      expect { reservation(:confirmed).expire(now: reserved_at + 3600) }
        .to raise_error(Ticketing::Reservation::InvalidTransition, "予約確定の予約は、期限切れにできません")
    end
  end

  it "状態を外から書き換えるメソッドはない" do
    expect(reservation(:pending)).not_to respond_to(:status=)
  end
end
