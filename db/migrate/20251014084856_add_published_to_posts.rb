class AddPublishedToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :published, :boolean
  end
end
