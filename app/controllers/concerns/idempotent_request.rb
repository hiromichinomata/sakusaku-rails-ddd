# Idempotency-Key ヘッダーが同じリクエストには、最初の応答をそのまま返す。
# 通信が切れて、クライアントが同じ申込を送り直しても、2回申し込まれないようにする。
module IdempotentRequest
  def idempotently(&)
    key = request.headers["Idempotency-Key"]
    return yield if key.blank?

    record = IdempotencyKey.find_by(key: key)
    return render(json: record.response_body, status: record.response_status) if record&.completed?
    return render_in_progress if record

    run_once(IdempotencyKey.create!(key: key, request_path: request.path), &)
  rescue ActiveRecord::RecordNotUnique
    render_in_progress # 同じキーのリクエストが、ちょうど同時に来た
  end

  private

  def run_once(record)
    yield
    record.update!(response_status: response.status, response_body: JSON.parse(response.body))
  rescue StandardError
    record.destroy! # 応答を返せなかったので、同じキーでやり直せるようにする
    raise
  end

  def render_in_progress
    render json: { error: { code: "request_in_progress", message: "同じ申込を処理しています" } }, status: :conflict
  end
end
