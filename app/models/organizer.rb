class Organizer < ApplicationRecord
  has_many :events, dependent: :nullify

  validates :name, presence: true
  validates :max_attendees_per_reservation,
            numericality: { only_integer: true, in: Ticketing::ReservationCount::MIN..Ticketing::ReservationCount::MAX }
  validates :refund_hours_before_start, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
