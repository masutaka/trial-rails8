class ConvertNotificationsToPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # post_id の外部キーとインデックスを削除
    remove_foreign_key :notifications, :posts
    remove_index :notifications, :post_id

    # post_id カラムを削除
    remove_column :notifications, :post_id, :bigint

    # Polymorphic な関連付けを追加
    add_reference :notifications, :notifiable, polymorphic: true, null: false
  end
end
