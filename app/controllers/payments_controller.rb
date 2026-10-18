class PaymentsController < ApplicationController
  def create
    @reservation = Reservation.find(params[:reservation_id])

    unless @reservation.pending?
      redirect_to @reservation, alert: "この予約はお支払いできません。"
      return
    end

    if @reservation.created_at < 15.minutes.ago
      Reservation.transaction do
        @reservation.update!(status: :expired)
        Ticketing::ReleaseSeats.new.call(event_id: @reservation.event_id, count: @reservation.quantity)
      end
      redirect_to @reservation, alert: "お支払いの期限を過ぎたため、予約は取り消されました。"
      return
    end

    amount = @reservation.total_price
    charge_id = Billing::PaymentGateway.charge(amount: amount.yen, token: params[:token])
    Reservation.transaction do
      @reservation.create_payment!(amount: amount.yen, charge_id: charge_id)
      @reservation.update!(status: :confirmed)
      DomainEvents.publish(Ticketing::ReservationConfirmed.new(reservation_id: @reservation.id,
                                                               event_id: @reservation.event_id,
                                                               occurred_at: Time.current))
    end

    redirect_to @reservation, notice: "お支払いが完了し、予約が確定しました。"
  rescue Billing::PaymentGateway::CardDeclined => e
    redirect_to @reservation, alert: e.message
  end
end
