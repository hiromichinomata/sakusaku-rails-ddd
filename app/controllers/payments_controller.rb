class PaymentsController < ApplicationController
  def create
    reservation = Ticketing::ReservationRepository.new.find(params[:reservation_id])
    now = Time.current

    if reservation.status == :pending && now > reservation.payment_deadline
      Ticketing::ExpireReservation.new.call(reservation_id: reservation.id, now: now)
      redirect_to reservation_path(reservation.id), alert: "お支払いの期限を過ぎたため、予約は取り消されました。"
      return
    end

    unless reservation.status == :pending
      redirect_to reservation_path(reservation.id), alert: "この予約はお支払いできません。"
      return
    end

    amount = reservation.total_price
    charge_id = Billing::PaymentGateway.charge(amount: amount.yen, token: params[:token])
    ApplicationRecord.transaction do
      Payment.create!(reservation_id: reservation.id, amount: amount.yen, charge_id: charge_id)
      Ticketing::ConfirmReservation.new.call(reservation_id: reservation.id, now: now)
    end

    redirect_to reservation_path(reservation.id), notice: "お支払いが完了し、予約が確定しました。"
  rescue Billing::PaymentGateway::CardDeclined => e
    redirect_to reservation_path(params[:reservation_id]), alert: e.message
  end
end
