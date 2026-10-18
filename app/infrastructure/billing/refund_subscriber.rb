module Billing
  # 予約がキャンセルされたら、返金する金額があるときだけ返金のジョブを積む。
  # 返金するかどうかは予約のコンテキストが決め、決済は金額を受け取って返すだけ。
  class RefundSubscriber
    def call(event)
      return unless event.refund_amount

      RefundPaymentJob.perform_later(event.reservation_id, event.refund_amount.yen)
    end
  end
end
