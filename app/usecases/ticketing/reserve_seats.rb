module Ticketing
  # 申込のユースケース。席を押さえて、予約を作る
  class ReserveSeats
    def initialize(inventories: InventoryRepository.new, reservations: ReservationRepository.new,
                   sales_infos: SalesInfoReader.new)
      @inventories = inventories
      @reservations = reservations
      @sales_infos = sales_infos
      @double_booking = DoubleBookingCheck.new(reservations)
    end

    def call(event_id:, name:, email:, count:, now: Time.current)
      applicant = Applicant.new(name: name, email: email)
      count = ReservationCount.new(count)

      ApplicationRecord.transaction do
        sales_info = @sales_infos.find(event_id)
        sales_info.sales_period.ensure_open!(now)
        @double_booking.ensure_not_double_booked!(event_id: event_id, email: applicant.email)

        inventory = @inventories.find(event_id)
        inventory.reserve(count)
        @inventories.save(inventory)

        @reservations.add(
          Reservation.apply(event_id: event_id, applicant: applicant, count: count, price: sales_info.price)
        )
      end
    end
  end
end
