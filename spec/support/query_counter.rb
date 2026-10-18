# ブロックの中で流れた SQL の数を数える（トランザクションの BEGIN・COMMIT などは数えない）
def count_queries(&block)
  count = 0
  counter = lambda do |*, payload|
    count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)
  end
  ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
  count
end
