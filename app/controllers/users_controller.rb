class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[show following followers]
  before_action :resume_session, only: %i[show following followers]
  before_action :set_user

  def show
    @posts = @user.posts.where(published: true).order(published_at: :desc)
  end

  def following
    @users = @user.following.order(:username)
  end

  def followers
    @users = @user.followers.order(:username)
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end
end
