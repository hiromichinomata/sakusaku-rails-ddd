module Ticketing
  # 申込のユースケース。席を押さえて、予約を作る
  class ReserveSeats
    def initialize(inventories: InventoryRepository.new, reservations: ReservationRepository.new,
                   sales_infos: SalesInfoReader.new)
      @inventories = inventories
      @sales_infos = sales_infos
      @double_booking = DoubleBookingCheck.new(reservations)
      @allocate = AllocateSeats.new(reservations: reservations)
    end

    def call(event_id:, name:, email:, count:, now: Time.current)
      applicant = Applicant.new(name: name, email: email)
      count = ReservationCount.new(count)

      ApplicationRecord.transaction do
        sales_info = @sales_infos.find(event_id)
        sales_info.sales_period.ensure_open!(now)
        sales_info.policy.ensure_count_allowed!(count)
        @double_booking.ensure_not_double_booked!(event_id: event_id, email: applicant.email)

        inventory = @inventories.find(event_id, lock: true)
        inventory.ensure_first_come!
        reservation = @allocate.call(inventory: inventory, applicant: applicant, count: count,
                                     price: sales_info.price, now: now)
        @inventories.save(inventory)
        reservation
      end
    end
  end
end
