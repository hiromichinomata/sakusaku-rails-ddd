class Event < ApplicationRecord
  has_many :reservations, dependent: :destroy

  validates :title, :venue, :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def reserved_count
    reservations.active.sum(:quantity)
  end

  def remaining_seats
    capacity - reserved_count
  end
end
