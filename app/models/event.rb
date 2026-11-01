class Event < ApplicationRecord
  belongs_to :organizer, optional: true
  has_many :reservations, dependent: :destroy
  has_one :ticket_inventory, dependent: :destroy

  validates :title, :venue, :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def reserved_count
    ticket_inventory&.reserved_count || 0
  end

  def remaining_seats
    capacity - reserved_count
  end
end
