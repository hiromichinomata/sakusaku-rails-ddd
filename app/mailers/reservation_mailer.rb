class ReservationMailer < ApplicationMailer
  def payment_request
    @reservation = params[:reservation]
    mail to: @reservation.email, subject: "【うめチケット】お支払いのお願い：#{@reservation.event.title}"
  end

  def confirmed
    @reservation = params[:reservation]
    mail to: @reservation.email, subject: "【うめチケット】予約が確定しました：#{@reservation.event.title}"
  end
end
