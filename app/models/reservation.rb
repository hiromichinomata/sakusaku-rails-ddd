class Reservation < ApplicationRecord
  belongs_to :event

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    canceled: "canceled",
    expired: "expired"
  }, default: :pending

  scope :active, -> { where(status: %w[pending confirmed]) }

  def total_price
    Money.new(price) * quantity
  end

  def payment_deadline
    payment_due_at
  end
end
