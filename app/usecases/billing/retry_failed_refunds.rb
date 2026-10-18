module Billing
  # 返金に失敗した決済を、返金のジョブに積み直す。決済サービスが直ったあとに、運用で使う
  class RetryFailedRefunds
    # 積み直した予約のIDの一覧を返す
    def call
      Payment.refund_failed.order(:id).map do |payment|
        RefundPaymentJob.perform_later(payment.reservation_id, payment.amount)
        payment.reservation_id
      end
    end
  end
end
