class PaymentsController < ApplicationController
  def create
    result = Ticketing::PayForReservation.new.call(reservation_id: params[:reservation_id], token: params[:token])
    notice = result.already_paid ? "お支払いはすでに完了しています。" : "お支払いが完了し、予約が確定しました。"
    redirect_to reservation_path(params[:reservation_id]), notice: notice
  rescue Ticketing::Reservation::PaymentDeadlinePassed
    redirect_to reservation_path(params[:reservation_id]), alert: "お支払いの期限を過ぎたため、予約は取り消されました。"
  rescue Ticketing::BusinessRuleViolation
    redirect_to reservation_path(params[:reservation_id]), alert: "この予約はお支払いできません。"
  rescue Billing::CardDeclined => e
    redirect_to reservation_path(params[:reservation_id]), alert: e.message
  rescue Billing::GatewayUnavailable
    redirect_to reservation_path(params[:reservation_id]),
                alert: "決済サービスにつながりませんでした。時間をおいて、もう一度お試しください。"
  end
end
