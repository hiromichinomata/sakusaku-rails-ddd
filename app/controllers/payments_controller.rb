class PaymentsController < ApplicationController
  def create
    @reservation = Reservation.find(params[:reservation_id])

    unless @reservation.pending?
      redirect_to @reservation, alert: "この予約はお支払いできません。"
      return
    end

    if @reservation.created_at < 15.minutes.ago
      @reservation.update!(status: :expired)
      redirect_to @reservation, alert: "お支払いの期限を過ぎたため、予約は取り消されました。"
      return
    end

    amount = @reservation.total_price
    charge_id = Billing::PaymentGateway.charge(amount: amount, token: params[:token])
    @reservation.create_payment!(amount: amount, charge_id: charge_id)
    @reservation.update!(status: :confirmed)

    redirect_to @reservation, notice: "お支払いが完了し、予約が確定しました。"
  rescue Billing::PaymentGateway::CardDeclined => e
    redirect_to @reservation, alert: e.message
  end
end
