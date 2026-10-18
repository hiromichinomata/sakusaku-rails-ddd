class Reservation < ApplicationRecord
  belongs_to :event

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_within_remaining_seats

  private

  def quantity_within_remaining_seats
    return if event.nil? || quantity.nil?

    remaining = event.capacity - event.reservations.where.not(id: id).sum(:quantity)
    if quantity > remaining
      errors.add(:quantity, :exceeds_remaining_seats, count: remaining)
    end
  end
end
