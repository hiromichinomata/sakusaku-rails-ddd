class Reservation < ApplicationRecord
  belongs_to :event
  has_one :payment, dependent: :destroy

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    canceled: "canceled",
    expired: "expired"
  }, default: :pending

  scope :active, -> { where(status: %w[pending confirmed]) }

  before_create :copy_price_from_event

  def total_price
    Money.new(price) * quantity
  end

  private

  def copy_price_from_event
    self.price ||= event&.price
  end
end
