class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ edit update destroy ]
  before_action :authorize_owner, only: %i[ edit update destroy ]
  before_action :ensure_post_published, only: %i[ create ]

  # POST /posts/:post_slug/comments
  def create
    # @post is already loaded by ensure_post_published
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      render turbo_stream: [
        turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
        turbo_stream.replace("new_comment", partial: "comments/new_comment_form", locals: { post: @post }),
        turbo_stream.update("comment_count_#{@post.id}", "(#{@post.comments.count})")
      ]
    else
      render turbo_stream: turbo_stream.replace("new_comment", partial: "comments/new_comment_form", locals: { post: @post, comment: @comment }),
             status: :unprocessable_entity
    end
  end

  # GET /comments/:id/edit
  def edit
  end

  # PATCH/PUT /comments/:id
  def update
    if @comment.update(comment_params)
      render partial: "comments/comment", locals: { comment: @comment }
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /comments/:id
  def destroy
    @post = @comment.post
    @comment.destroy

    render turbo_stream: [
      turbo_stream.remove(helpers.dom_id(@comment)),
      turbo_stream.update("comment_count_#{@post.id}", "(#{@post.comments.count})")
    ]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Check if the current user is the owner of the comment
    def authorize_owner
      unless @comment.user == Current.user
        redirect_to root_url, alert: "You are not authorized to perform this action."
      end
    end

    # Ensure the post is published before allowing comments
    def ensure_post_published
      @post = Post.find_by!(slug: params[:post_slug])
      return if @post.published

      redirect_to post_url(@post), alert: "この記事は未公開のため、コメントを投稿できません。"
    end

    # Only allow a list of trusted parameters through.
    def comment_params
      params.expect(comment: [ :body ])
    end
end
