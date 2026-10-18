# 申込のフォーム。画面や API から届いた入力の形を確かめ、ユースケースに渡す値にする
class ReservationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :quantity, :integer, default: 1

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :quantity, numericality: { only_integer: true, greater_than: 0,
                                       less_than_or_equal_to: Ticketing::ReservationCount::MAX }

  # ユースケースの引数にする
  def to_h
    { name: name, email: email, count: quantity }
  end

  # 業務のルールに反したことを、フォームのエラーとして表す
  def add_business_error(error)
    case error
    when Ticketing::Inventory::NotEnoughSeats
      errors.add(:quantity, :exceeds_remaining_seats, count: error.remaining_seats)
    when Ticketing::Reservation::AlreadyReserved
      errors.add(:email, :already_reserved)
    else
      errors.add(:base, error.message)
    end
  end
end
