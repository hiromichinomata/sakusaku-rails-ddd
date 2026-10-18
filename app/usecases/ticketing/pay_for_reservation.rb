module Ticketing
  # 仮予約の支払い。決済のコンテキストに支払いを頼み、予約確定にする
  class PayForReservation
    # already_paid は、すでに支払いが済んでいて、今回は何もしなかったとき true
    Result = Data.define(:reservation, :already_paid)

    def initialize(reservations: ReservationRepository.new, billing: Billing::ChargeReservation.new)
      @reservations = reservations
      @billing = billing
    end

    def call(reservation_id:, token:, now: Time.current)
      reservation = @reservations.find(reservation_id)
      # 同じ支払いが2回届いても、2回目は何もしない（ボタンの連打・通信のやり直し）
      return Result.new(reservation: reservation, already_paid: true) if reservation.status == :confirmed

      expire_if_deadline_passed(reservation, now)
      reservation.ensure_payable!(now: now)

      # 決済のコンテキストに頼む（トランザクションの外）。やり直しても、受け取るのは1回分
      @billing.call(reservation_id: reservation.id, amount: reservation.total_price, token: token)

      confirmed = ConfirmReservation.new(reservations: @reservations).call(reservation_id: reservation.id, now: now)
      Result.new(reservation: confirmed, already_paid: false)
    end

    private

    def expire_if_deadline_passed(reservation, now)
      return unless reservation.status == :pending && now > reservation.payment_deadline

      ExpireReservation.new(reservations: @reservations).call(reservation_id: reservation.id, now: now)
      raise Reservation::PaymentDeadlinePassed
    end
  end
end
