require "rails_helper"

RSpec.describe "同じメールアドレスの同時の申込", :concurrency do
  self.use_transactional_tests = false

  let(:event) { create(:event, capacity: 4, price: 1500) }

  it "二重予約のチェックを2人ともすり抜けても、データベースが1件だけにする" do
    barrier = Concurrent::CyclicBarrier.new(2)
    reservations = Ticketing::ReservationRepository.new
    allow(reservations).to receive(:active_exists?).and_wrap_original do |original, **options|
      original.call(**options).tap { wait_for_each_other(barrier) }
    end

    results = run_concurrently(2) do
      Ticketing::ReserveSeats.new(reservations: reservations)
                             .call(event_id: event.id, name: "初花", email: "hatsuka@example.com", count: 1)
    end

    expect(results.grep(Exception).map(&:class)).to eq([ Ticketing::Reservation::AlreadyReserved ])
    expect(Reservation.where(event: event).count).to eq(1)
    expect(event.ticket_inventory.reload.reserved_count).to eq(1)
  end
end
