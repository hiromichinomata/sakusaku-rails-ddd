# Rails.event で記録した業務のイベントを、1行に1件の JSON として log/events_{環境}.log に書く。
# ログを集めるサービスに送るときは、このファイルを読み込ませる。
class EventLogSubscriber
  # Rails 自身も Rails.event に出来事（SQL など）を流すので、業務のイベントだけを書く
  BUSINESS_EVENTS = %w[ticketing. billing.].freeze

  def initialize(path)
    @logger = Logger.new(path)
    @logger.formatter = ->(*, message) { "#{message}\n" }
  end

  def emit(event)
    return unless event[:name].start_with?(*BUSINESS_EVENTS)

    @logger.info(
      { at: Time.at(event[:timestamp] / 1_000_000_000r).iso8601(3), name: event[:name],
        payload: event[:payload], tags: event[:tags], context: event[:context] }.to_json
    )
  end
end

Rails.event.subscribe(EventLogSubscriber.new(Rails.root.join("log/events_#{Rails.env}.log")))
