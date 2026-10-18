class Payment < ApplicationRecord
  belongs_to :reservation

  # 決済の状態。予約の状態（キャンセル済みなど）とは別に変わる
  enum :status, { paid: "paid", refunded: "refunded", refund_failed: "refund_failed" }, default: :paid
end
