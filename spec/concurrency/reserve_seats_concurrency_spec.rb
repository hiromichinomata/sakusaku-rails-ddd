require "rails_helper"

RSpec.describe "同時の申込", :concurrency do
  self.use_transactional_tests = false

  let(:event) { create(:event, capacity: 4, price: 1500) }

  before do # 先客が3人。残り1席
    3.times do |index|
      Ticketing::ReserveSeats.new.call(event_id: event.id, name: "先客#{index}", email: "first#{index}@example.com", count: 1)
    end
  end

  # 2人とも残席を読み終えてから書き込むように、読んだところで待ち合わせる
  def inventories_that_wait(barrier)
    Ticketing::InventoryRepository.new.tap do |repository|
      allow(repository).to receive(:find).and_wrap_original do |original, *args, **options|
        original.call(*args, **options).tap { wait_for_each_other(barrier) }
      end
    end
  end

  it "残り1席に2人が同時に申し込んでも、定員を超えない" do
    barrier = Concurrent::CyclicBarrier.new(2)
    inventories = inventories_that_wait(barrier)

    results = run_concurrently(2) do |index|
      Ticketing::ReserveSeats.new(inventories: inventories)
                             .call(event_id: event.id, name: "申込者#{index}", email: "attendee#{index}@example.com", count: 1)
    end

    reserved = Reservation.active.where(event: event).sum(:quantity)
    puts "成功: #{results.count { |r| r.is_a?(Ticketing::Reservation) }}件 / " \
         "有効な予約の人数: #{reserved}人 / 残席の予約済みの人数: #{event.ticket_inventory.reload.reserved_count}人（定員4人）"
    expect(reserved).to be <= 4
  end
end
