require "net/http"

module Billing
  # 本番で使う、うめペイの HTTP API の窓口（本書用の架空の API）。
  # うめペイの言葉（charge・source・HTTP のステータス）は、このクラスの外に出さない。
  class UmepayGateway
    BASE_URL = URI("https://api.umepay.example")

    def initialize(api_key:, open_timeout: 2, read_timeout: 5)
      @api_key = api_key
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def charge(amount:, token:, idempotency_key:)
      post("/v1/charges", { amount: amount.yen, currency: "jpy", source: token }, idempotency_key).fetch("id")
    end

    def refund(charge_id:, amount:, idempotency_key:)
      post("/v1/refunds", { charge: charge_id, amount: amount.yen }, idempotency_key).fetch("id")
    end

    private

    def post(path, params, idempotency_key)
      request = Net::HTTP::Post.new(path, "Content-Type" => "application/json",
                                          "Authorization" => "Bearer #{@api_key}",
                                          "Idempotency-Key" => idempotency_key)
      request.body = params.to_json

      response = Net::HTTP.start(BASE_URL.host, BASE_URL.port, use_ssl: true,
                                 open_timeout: @open_timeout, read_timeout: @read_timeout) do |http|
        http.request(request)
      end

      case response
      when Net::HTTPSuccess then JSON.parse(response.body)
      when Net::HTTPPaymentRequired then raise CardDeclined, "カードが利用できませんでした"
      else raise GatewayUnavailable, "うめペイが #{response.code} を返しました"
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
      raise GatewayUnavailable, "うめペイにつながりませんでした（#{e.class}）"
    end
  end
end
