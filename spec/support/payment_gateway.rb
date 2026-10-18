RSpec.configure do |config|
  # 手元の決済の窓口が覚えている結果を、テストごとに消す
  config.before { Billing::FakePaymentGateway.reset! }
end
