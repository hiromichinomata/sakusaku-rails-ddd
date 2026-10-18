# 決済のコンテキスト
module Billing
  # 環境ごとに、決済の窓口（アダプター）を選ぶ
  def self.gateway
    case Rails.configuration.x.payment_gateway
    when :umepay then UmepayGateway.new(api_key: ENV.fetch("UMEPAY_API_KEY"))
    else FakePaymentGateway.new
    end
  end
end
