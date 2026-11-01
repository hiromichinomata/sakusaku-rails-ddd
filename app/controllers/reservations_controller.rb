class ReservationsController < ApplicationController
  def show
    @reservation = Reservation.find(params[:id])
    @cancellation_deadline = Ticketing::SalesInfoReader.new.find(@reservation.event_id).cancellation_deadline
    @refundable = @reservation.confirmed? && @cancellation_deadline.refundable_at?(Time.current)
  end

  def create
    @event = Event.find(params[:event_id])
    @form = ReservationForm.new(reservation_params)
    return render_event_page unless @form.valid?

    reservation = Ticketing::ReserveSeats.new.call(event_id: @event.id, **@form.to_h)
    redirect_to reservation_path(reservation.id), notice: reserved_notice(reservation)
  rescue Ticketing::BusinessRuleViolation => e
    @form.add_business_error(e)
    render_event_page
  end

  def cancel
    @reservation = Reservation.find(params[:id])
    result = Ticketing::CancelReservation.new.call(reservation_id: @reservation.id)

    message = result.refund_amount ? "キャンセルしました。#{result.refund_amount}を返金します。" : "キャンセルしました。"
    redirect_to @reservation, notice: message
  rescue Ticketing::BusinessRuleViolation => e
    redirect_to @reservation, alert: e.message
  end

  private

  def reservation_params
    params.expect(reservation: %i[name email quantity])
  end

  def render_event_page
    render "events/show", status: :unprocessable_content
  end

  def reserved_notice(reservation)
    reservation.status == :confirmed ? "予約が確定しました。" : "仮予約しました。15分以内にお支払いください。"
  end
end
