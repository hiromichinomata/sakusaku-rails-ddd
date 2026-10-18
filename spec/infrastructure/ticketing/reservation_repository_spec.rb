require "rails_helper"

RSpec.describe Ticketing::ReservationRepository do
  let(:repository) { described_class.new }
  let(:event) { create(:event, price: 1500) }

  def build_reservation(email: "hatsuka@example.com", count: 2)
    Ticketing::Reservation.new(
      event_id: event.id,
      applicant: Ticketing::Applicant.new(name: "初花", email: email),
      count: Ticketing::ReservationCount.new(count),
      price: Money.new(1500)
    )
  end

  describe "#add" do
    it "新しい予約を保存して、IDの付いた予約を返す" do
      saved = repository.add(build_reservation)

      expect(saved.id).to be_present
      expect(saved.total_price).to eq(Money.new(3000))
      expect(::Reservation.find(saved.id).email).to eq("hatsuka@example.com")
    end

    it "同じメールアドレスの有効な予約があれば Ticketing::Reservation::AlreadyReserved" do
      repository.add(build_reservation)

      expect { repository.add(build_reservation) }.to raise_error(Ticketing::Reservation::AlreadyReserved)
    end
  end

  describe "#find" do
    it "保存した予約を、ドメインのオブジェクトとして読み込む" do
      saved = repository.add(build_reservation)

      found = repository.find(saved.id)

      expect(found).to eq(saved)
      expect(found.applicant.email).to eq(EmailAddress.new("hatsuka@example.com"))
      expect(found.status).to eq(:pending)
    end

    it "なければ Ticketing::NotFound" do
      expect { repository.find(0) }.to raise_error(Ticketing::NotFound)
    end
  end

  describe "#active_exists?" do
    it "同じイベント・同じメールアドレスの有効な予約があるかを調べる" do
      repository.add(build_reservation)

      expect(repository.active_exists?(event_id: event.id, email: EmailAddress.new("hatsuka@example.com"))).to be(true)
      expect(repository.active_exists?(event_id: event.id, email: EmailAddress.new("marigold@example.com"))).to be(false)
    end
  end
end
