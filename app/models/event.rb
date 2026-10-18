class Event < ApplicationRecord
  belongs_to :organizer, optional: true
  has_many :reservations, dependent: :destroy
  has_one :ticket_inventory, dependent: :destroy

  validates :title, :venue, :starts_at, presence: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :capacity_not_below_reserved, on: :update

  def reserved_count
    ticket_inventory&.reserved_count || 0
  end

  def remaining_seats
    capacity - reserved_count
  end

  private

  def capacity_not_below_reserved
    return unless capacity_changed? && capacity.present?

    errors.add(:capacity, :below_reserved, count: reserved_count) if capacity < reserved_count
  end
end
