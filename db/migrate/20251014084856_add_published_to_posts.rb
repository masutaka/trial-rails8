class AddPublishedToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :published, :boolean, default: false, null: false
    add_index :posts, :published_at
    add_index :posts, :published
    add_index :posts, [ :published, :published_at ]
  end
end
