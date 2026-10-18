class Reservation < ApplicationRecord
  MAX_QUANTITY = 4

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
  validates :email, uniqueness: { scope: :event_id, conditions: -> { active }, message: :already_reserved },
                    on: :create
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validate :quantity_within_remaining_seats
  validate :event_accepting_reservations, on: :create

  before_create :confirm_if_free
  after_create_commit :send_payment_request_mail, if: :pending?
  after_update_commit :send_confirmed_mail, if: -> { saved_change_to_status?(to: "confirmed") }

  def total_price
    event.price * quantity
  end

  private

  def quantity_within_remaining_seats
    return if event.nil? || quantity.nil?

    remaining = event.capacity - event.reservations.active.where.not(id: id).sum(:quantity)
    if quantity > remaining
      errors.add(:quantity, :exceeds_remaining_seats, count: remaining)
    end
  end

  def event_accepting_reservations
    return if event.nil?

    errors.add(:base, :reservation_closed) if event.starts_at <= Time.current
  end

  def confirm_if_free
    self.status = :confirmed if event.price.zero?
  end

  def send_payment_request_mail
    ReservationMailer.with(reservation: self).payment_request.deliver_later
  end

  def send_confirmed_mail
    ReservationMailer.with(reservation: self).confirmed.deliver_later
  end
end
