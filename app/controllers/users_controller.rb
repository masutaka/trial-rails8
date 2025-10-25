class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[show]

  def show
    @user = User.find_by!(username: params[:username])
    @posts = @user.posts.where(published: true).order(published_at: :desc)
  end
end
