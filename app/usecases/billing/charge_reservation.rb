module Billing
  # 予約の支払い金額を受け取り、決済の記録を残す。決済のコンテキストの入口
  class ChargeReservation
    def initialize(gateway: Billing.gateway)
      @gateway = gateway
    end

    # 支払いIDを返す。同じ予約の支払いがすでに記録されていれば、決済サービスを呼ばずにそれを返す
    def call(reservation_id:, amount:, token:)
      existing = Payment.find_by(reservation_id: reservation_id)
      return existing.charge_id if existing

      charge_id = @gateway.charge(amount: amount, token: token,
                                  idempotency_key: "charge-reservation-#{reservation_id}-#{token}")
      Payment.create!(reservation_id: reservation_id, amount: amount.yen, charge_id: charge_id)
      Rails.event.notify("billing.charged", reservation_id: reservation_id, charge_id: charge_id, amount: amount.yen)
      charge_id
    end
  end
end
