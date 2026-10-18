class Reservation < ApplicationRecord
  MAX_QUANTITY = 4

  belongs_to :event

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    canceled: "canceled",
    expired: "expired"
  }, default: :pending

  scope :active, -> { where(status: %w[pending confirmed]) }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :event_id, conditions: -> { active }, message: :already_reserved },
                    on: :create
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validate :quantity_within_remaining_seats
  validate :event_accepting_reservations, on: :create

  def total_price
    event.price * quantity
  end

  private

  def quantity_within_remaining_seats
    return if event.nil? || quantity.nil?

    remaining = event.capacity - event.reservations.where.not(id: id).sum(:quantity)
    if quantity > remaining
      errors.add(:quantity, :exceeds_remaining_seats, count: remaining)
    end
  end

  def event_accepting_reservations
    return if event.nil?

    errors.add(:base, :reservation_closed) if event.starts_at <= Time.current
  end
end
