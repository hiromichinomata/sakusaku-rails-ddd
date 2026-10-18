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

  private

  def reservation_params
    params.expect(reservation: %i[name email quantity])
  end
end
