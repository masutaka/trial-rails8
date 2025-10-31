class FollowsController < ApplicationController
  before_action :require_authentication
  before_action :set_user

  def create
    Current.user.follow(@user)
    head :ok
  end

  def destroy
    Current.user.unfollow(@user)
    head :ok
  end

  private

  def set_user
    @user = User.find_by!(username: params[:user_username])
  end
end
