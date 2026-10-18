module Billing
  # 予約のキャンセルを受けて、決済サービスに返金を頼む。
  # 決済サービスにつながらなければ、少しずつ間をあけてやり直す。
  class RefundPaymentJob < ApplicationJob
    queue_as :default

    retry_on PaymentGateway::Unavailable, wait: :polynomially_longer, attempts: 5 do |job, _error|
      Payment.find_by!(reservation_id: job.arguments.first).update!(status: :refund_failed)
    end

    def perform(reservation_id, amount_yen)
      payment = Payment.find_by!(reservation_id: reservation_id)
      return if payment.refunded? # すでに返金済みなら、もう一度は頼まない

      refund_id = PaymentGateway.refund(charge_id: payment.charge_id, amount: amount_yen)
      payment.update!(status: :refunded, refund_id: refund_id)
    end
  end
end
