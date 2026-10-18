# 決済のコンテキストの記録。予約とは reservation_id だけでつながる（予約のモデルは知らない）
class Payment < ApplicationRecord
  # 決済の状態。予約の状態（キャンセル済みなど）とは別に変わる
  enum :status, { paid: "paid", refunded: "refunded", refund_failed: "refund_failed" }, default: :paid
end
