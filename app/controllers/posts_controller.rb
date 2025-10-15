class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :authorize_author, only: %i[ edit update destroy ]

  # GET /posts
  def index
    resume_session
    @posts = Post.visible_to(Current.user).includes(:comments).order(published_at: :desc)
  end

  # GET /posts/1
  def show
    resume_session
    @previous_post = @post.previous_post
    @next_post = @post.next_post
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  def create
    @post = Post.new(post_params)
    @post.user = Current.user

    if @post.save
      redirect_to @post, notice: "Post was successfully created.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy!

    redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    # Check if the current user is the author of the post
    def authorize_author
      unless @post.user == Current.user
        redirect_to posts_path, alert: "You are not authorized to perform this action."
      end
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.expect(post: [ :title, :body, :published_at, :slug ])
    end
end
