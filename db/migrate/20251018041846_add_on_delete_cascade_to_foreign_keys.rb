class AddOnDeleteCascadeToForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # comments → posts
    remove_foreign_key :comments, :posts
    add_foreign_key :comments, :posts, on_delete: :cascade

    # comments → users
    remove_foreign_key :comments, :users
    add_foreign_key :comments, :users, on_delete: :cascade

    # posts → users
    remove_foreign_key :posts, :users
    add_foreign_key :posts, :users, on_delete: :cascade

    # sessions → users
    remove_foreign_key :sessions, :users
    add_foreign_key :sessions, :users, on_delete: :cascade
  end
end
