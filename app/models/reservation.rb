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

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: Ticketing::ReservationCount::MAX }

  before_create :copy_price_from_event
  after_create_commit :send_payment_request_mail, if: :pending?
  after_update_commit :send_confirmed_mail, if: -> { saved_change_to_status?(to: "confirmed") }

  def total_price
    Money.new(price) * quantity
  end

  private

  def copy_price_from_event
    self.price ||= event&.price
  end

  def send_payment_request_mail
    ReservationMailer.with(reservation: self).payment_request.deliver_later
  end

  def send_confirmed_mail
    ReservationMailer.with(reservation: self).confirmed.deliver_later
  end
end
