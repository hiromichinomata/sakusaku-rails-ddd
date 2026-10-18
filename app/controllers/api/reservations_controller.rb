module Api
  class ReservationsController < BaseController
    include IdempotentRequest

    def create
      idempotently do
        form = ReservationForm.new(params.expect(reservation: %i[name email quantity]))
        next render(json: { errors: form.errors.to_hash(true) }, status: :unprocessable_content) unless form.valid?

        reservation = Ticketing::ReserveSeats.new.call(event_id: params[:event_id], **form.to_h)
        render json: {
          reservation: { id: reservation.id, status: reservation.status, total_price: reservation.total_price.yen }
        }, status: :created
      end
    end
  end
end
