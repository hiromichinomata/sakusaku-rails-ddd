module ConcurrencyHelpers
  # ブロックを、別々のスレッド（別々のデータベース接続）で同時に動かし、それぞれの結果か例外を返す
  def run_concurrently(count)
    threads = Array.new(count) do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection { yield(index) }
      rescue => e
        e
      end
    end
    threads.map(&:value)
  end

  # 2つのスレッドが、ここまで来るまで互いに待つ（最大1秒）
  def wait_for_each_other(barrier)
    barrier.wait(1)
  end
end

RSpec.configure do |config|
  config.include ConcurrencyHelpers, :concurrency

  # 別のスレッドから見えるように、このテストではトランザクションを使わず、終わったらテーブルを空にする
  config.around(:each, :concurrency) do |example|
    example.run
  ensure
    connection = ActiveRecord::Base.connection
    connection.truncate_tables(*(connection.tables - %w[schema_migrations ar_internal_metadata]))
  end
end
