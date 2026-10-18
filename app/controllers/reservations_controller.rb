class ReservationsController < ApplicationController
  def create
    @event = Event.find(params[:event_id])
    @reservation = @event.reservations.build(reservation_params)

    if @reservation.save
      redirect_to @event, notice: "予約しました。"
    else
      render "events/show", status: :unprocessable_content
    end
  end

  private

  def reservation_params
    params.expect(reservation: %i[name email quantity])
  end
end
