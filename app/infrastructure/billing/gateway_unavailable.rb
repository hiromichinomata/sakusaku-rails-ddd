module Billing
  # 決済サービスにつながらなかった（タイムアウト・障害）。時間をおいてやり直せば直ることがある
  class GatewayUnavailable < StandardError; end
end
