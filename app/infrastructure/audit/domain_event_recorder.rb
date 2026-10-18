module Audit
  # ドメインイベントを、Rails.event の構造化されたイベントとして記録する。
  # 業務の言葉（予約が作られた・キャンセルされた）でログを残し、予約IDでたどれるようにする。
  class DomainEventRecorder
    def call(event)
      payload = event.to_h.transform_values { |value| value.is_a?(Money) ? value.yen : value }
      Rails.event.notify(event.class.event_name, **payload)
    end
  end
end
