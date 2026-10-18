RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  # テストの「今」を固定する。実行した日によって結果が変わらないようにするため
  config.before { travel_to Time.zone.local(2026, 11, 1, 10, 0) }
  config.after { travel_back }
end
