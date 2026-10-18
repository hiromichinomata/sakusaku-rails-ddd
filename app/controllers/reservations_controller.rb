class ReservationsController < ApplicationController
  def show
    @reservation = Reservation.find(params[:id])
  end

  def create
    @event = Event.find(params[:event_id])
    @reservation = @event.reservations.build(reservation_params)

    if @reservation.save
      notice = @reservation.confirmed? ? "予約が確定しました。" : "仮予約しました。15分以内にお支払いください。"
      redirect_to @reservation, notice: notice
    else
      render "events/show", status: :unprocessable_content
    end
  end

  def cancel
    @reservation = Reservation.find(params[:id])

    if @reservation.canceled? || @reservation.expired?
      redirect_to @reservation, alert: "この予約はキャンセルできません。"
      return
    end

    payment = @reservation.payment
    if payment.present? && @reservation.event.starts_at - 3.days > Time.current
      refund_id = Billing::PaymentGateway.refund(charge_id: payment.charge_id, amount: payment.amount)
      payment.update!(status: :refunded, refund_id: refund_id)
      message = "キャンセルしました。#{ActiveSupport::NumberHelper.number_to_delimited(payment.amount)}円を返金します。"
    else
      message = "キャンセルしました。"
    end
    @reservation.update!(status: :canceled)

    redirect_to @reservation, notice: message
  end

  private

  def reservation_params
    params.expect(reservation: %i[name email quantity])
  end
end
