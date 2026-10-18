class CreateOrganizers < ActiveRecord::Migration[8.1]
  def change
    # 主催者と、主催者が決める予約のルール
    create_table :organizers do |t|
      t.string :name, null: false
      t.integer :max_attendees_per_reservation, null: false, default: 4
      t.integer :refund_hours_before_start, null: false, default: 72

      t.timestamps
    end
    add_reference :events, :organizer, foreign_key: true # 決めていないイベントは、既定のルール
  end
end
