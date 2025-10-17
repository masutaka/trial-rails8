class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read, :created_at ]
    add_index :notifications, [ :user_id, :created_at ]
  end
end
