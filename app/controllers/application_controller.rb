class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # 業務のイベントのログに、どのリクエストで起きたかを残す
  before_action { Rails.event.set_context(request_id: request.request_id) }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
