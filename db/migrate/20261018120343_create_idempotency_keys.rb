class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    # API の申込の Idempotency-Key と、そのときの応答を覚えておく
    create_table :idempotency_keys do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :request_path, null: false
      t.integer :response_status
      t.jsonb :response_body

      t.timestamps
    end
  end
end
