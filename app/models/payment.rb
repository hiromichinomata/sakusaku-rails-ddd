class Payment < ApplicationRecord
  belongs_to :reservation

  enum :status, { paid: "paid", refunded: "refunded" }, default: :paid
end
