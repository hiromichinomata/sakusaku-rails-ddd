module Api
  # JSON の API の親コントローラ。画面用の機能（CSRF の確認・ブラウザの確認）は持たない
  class BaseController < ActionController::API
    include DomainErrorResponses

    before_action { Rails.event.set_context(request_id: request.request_id) }

    rescue_from Ticketing::BusinessRuleViolation, Ticketing::NotFound do |error|
      status, code = domain_error_response(error)
      render json: { error: { code: code, message: error.message } }, status: status
    end
  end
end
