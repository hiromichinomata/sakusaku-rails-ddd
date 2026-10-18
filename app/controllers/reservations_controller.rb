class ReservationsController < ApplicationController
  def show
    @reservation = Reservation.find(params[:id])
  end

  def create
    @event = Event.find(params[:event_id])
    @reservation = @event.reservations.build(reservation_params)
    return render_event_page unless @reservation.valid?

    reservation = Ticketing::ReserveSeats.new.call(
      event_id: @event.id, name: @reservation.name, email: @reservation.email, count: @reservation.quantity
    )
    notice = reservation.status == :confirmed ? "予約が確定しました。" : "仮予約しました。15分以内にお支払いください。"
    redirect_to reservation_path(reservation.id), notice: notice
  rescue Ticketing::Inventory::NotEnoughSeats => e
    @reservation.errors.add(:quantity, :exceeds_remaining_seats, count: e.remaining_seats)
    render_event_page
  rescue Ticketing::BusinessRuleViolation => e
    @reservation.errors.add(:base, e.message)
    render_event_page
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
      message = "キャンセルしました。#{Money.new(payment.amount)}を返金します。"
    else
      message = "キャンセルしました。"
    end
    Reservation.transaction do
      @reservation.update!(status: :canceled)
      Ticketing::ReleaseSeats.new.call(event_id: @reservation.event_id, count: @reservation.quantity)
    end

    redirect_to @reservation, notice: message
  end

  private

  def reservation_params
    params.expect(reservation: %i[name email quantity])
  end

  def render_event_page
    render "events/show", status: :unprocessable_content
  end
end
