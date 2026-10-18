require "rails_helper"

RSpec.describe Ticketing::ReserveSeats do
  let(:usecase) { described_class.new }
  let(:event) { create(:event, capacity: 4, price: 1500, starts_at: Time.zone.local(2026, 11, 15, 10, 0)) }
  let(:inventories) { Ticketing::InventoryRepository.new }

  def reserve(count: 2, email: "hatsuka@example.com", now: Time.current)
    usecase.call(event_id: event.id, name: "初花", email: email, count: count, now: now)
  end

  it "席を押さえて、仮予約を作る" do
    reservation = reserve(count: 2)

    expect(reservation.id).to be_present
    expect(reservation.status).to eq(:pending)
    expect(reservation.total_price).to eq(Money.new(3000))
    expect(inventories.find(event.id).reserved_count).to eq(2)
  end

  it "予約が作られたことを、ドメインイベントで知らせる" do
    received = []
    subscription = ActiveSupport::Notifications.subscribe(Ticketing::ReservationCreated.event_name) do |*, payload|
      received << payload[:event]
    end

    reservation = reserve(count: 2)

    expect(received.map(&:reservation_id)).to eq([ reservation.id ])
    expect(received.first.status).to eq(:pending)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "無料のイベントは、予約確定になる" do
    event.update!(price: 0)

    expect(reserve.status).to eq(:confirmed)
  end

  it "残席を超えたら、予約も作らず、席も押さえない" do
    reserve(count: 3, email: "first@example.com")

    expect { reserve(count: 2) }.to raise_error(Ticketing::Inventory::NotEnoughSeats)

    expect(inventories.find(event.id).reserved_count).to eq(3)
    expect(Reservation.count).to eq(1)
  end

  it "二重予約なら、席を押さえない" do
    reserve(count: 1)

    expect { reserve(count: 1) }.to raise_error(Ticketing::Reservation::AlreadyReserved)

    expect(inventories.find(event.id).reserved_count).to eq(1)
  end

  it "二重予約のチェックをすり抜けても、データベースが止めて、押さえた席も元に戻る" do
    reserve(count: 1)
    reservations = Ticketing::ReservationRepository.new
    allow(reservations).to receive(:active_exists?).and_return(false) # 同時に申し込まれて、チェックをすり抜けた

    expect { described_class.new(reservations: reservations).call(event_id: event.id, name: "初花",
                                                                  email: "hatsuka@example.com", count: 1) }
      .to raise_error(Ticketing::Reservation::AlreadyReserved)

    expect(inventories.find(event.id).reserved_count).to eq(1)
  end

  it "受付期間が終わっていれば、申し込めない" do
    expect { reserve(now: event.starts_at) }.to raise_error(Ticketing::SalesPeriod::Closed)
  end

  it "主催者が決めていなければ、1回4人まで" do
    expect { reserve(count: 5) }.to raise_error(Ticketing::ReservationPolicy::TooManyAttendees, "1回の予約は4人までです")
  end

  it "主催者が6人までと決めたイベントは、5人で申し込める" do
    event.update!(capacity: 10, organizer: create(:organizer, max_attendees_per_reservation: 6))
    event.ticket_inventory.update!(capacity: 10)

    expect(reserve(count: 5).count.to_i).to eq(5)
  end

  it "サービス全体の上限（10人）を超える人数は、どのイベントでも作れない" do
    expect { reserve(count: 11) }.to raise_error(ArgumentError, "人数は1〜10人で指定してください: 11")
  end
end
