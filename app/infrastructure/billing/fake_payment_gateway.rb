module Billing
  # 開発とテストで使う、手元で動く決済の窓口。本書用の架空の決済サービス「うめペイ」の代わり。
  # tok_visa は成功、tok_declined はカードが使えない。同じ冪等キーの依頼には、同じ結果を返す。
  class FakePaymentGateway
    @results = {}

    class << self
      attr_reader :results

      def reset!
        results.clear
      end
    end

    def charge(amount:, token:, idempotency_key:)
      remember(idempotency_key) do
        raise CardDeclined, "カードが利用できませんでした" if token == "tok_declined"

        Rails.logger.info("[PaymentGateway] charge amount=#{amount.yen}")
        "ch_#{SecureRandom.hex(8)}"
      end
    end

    def refund(charge_id:, amount:, idempotency_key:)
      remember(idempotency_key) do
        Rails.logger.info("[PaymentGateway] refund charge_id=#{charge_id} amount=#{amount.yen}")
        "re_#{SecureRandom.hex(8)}"
      end
    end

    private

    def remember(idempotency_key)
      self.class.results[idempotency_key] ||= yield
    end
  end
end
