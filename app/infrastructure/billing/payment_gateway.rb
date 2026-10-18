module Billing
  # 本書用の架空の決済サービス「うめペイ」の代わりに、手元で動く決済の窓口。
  # トークン tok_visa は成功、tok_declined はカードが使えなかったものとして扱う。
  class PaymentGateway
    class CardDeclined < StandardError; end

    def self.charge(amount:, token:)
      raise CardDeclined, "カードが利用できませんでした" if token == "tok_declined"

      Rails.logger.info("[PaymentGateway] charge amount=#{amount}")
      "ch_#{SecureRandom.hex(8)}"
    end

    def self.refund(charge_id:, amount:)
      Rails.logger.info("[PaymentGateway] refund charge_id=#{charge_id} amount=#{amount}")
      "re_#{SecureRandom.hex(8)}"
    end
  end
end
