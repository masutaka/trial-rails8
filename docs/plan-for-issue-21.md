# Issue #21: コメントの投稿/編集/削除での画面遷移を止める - 実装計画

## 概要

コメントの投稿/編集/削除時に、ページ全体がリロードされて記事の先頭に遷移してしまう問題を解決し、ユーザーが現在の位置を保持したままコメント操作を完了できるようにする。

## 現状の問題点

- コメントの投稿時: `CommentsController#create` で `redirect_to post_url(@post)` が実行され、ページ全体が遷移する（app/controllers/comments_controller.rb:13）
- コメントの編集時: `GET /comments/:id/edit` で別ページに遷移し、更新後に `redirect_to post_url(@comment.post)` が実行される（app/controllers/comments_controller.rb:26）
- コメントの削除時: `CommentsController#destroy` で `redirect_to post_url(@post)` が実行される（app/controllers/comments_controller.rb:37）
- 本文が長い記事では、操作後に記事の先頭に戻ってしまい、ユーザー体験が悪い

## 実装方針

**Turbo Frames と Turbo Streams を併用する**

### Turbo Frames の使用箇所

- コメント編集: 各コメントを個別のフレームとして扱い、インライン編集を実現

### Turbo Streams の使用箇所

- コメント投稿: フォームのクリアとコメント一覧への追加を同時に行う
- コメント削除: DOM から要素を完全に削除
- コメント数更新: 投稿・削除時にコメント数を動的に更新

### この組み合わせを選択する理由

1. **複数箇所の同時更新**: コメント投稿時にフォームクリアと一覧追加を同時に実現
2. **状態管理不要**: JavaScriptで複雑な状態管理をする必要がない
3. **Rails標準**: Rails 7以降で標準搭載されている（既に `@hotwired/turbo-rails` がインポートされている - app/javascript/application.js:2）
4. **段階的な実装**: 各操作（投稿/編集/削除）を個別に段階的に実装できる
5. **テスト容易性**: Railsのテストツールで十分にテスト可能
6. **技術の一貫性**: すべて Hotwire の技術スタックで統一

## 実装手順

### Phase 1: コメント投稿のTurbo Streams対応

**目的**: 新規コメント投稿時の画面遷移を防ぎ、フォームをクリアしてコメント一覧に追加する

**変更内容**:

1. `app/views/posts/show.html.erb`:
   - コメントフォームエリアを `<div id="new_comment">` で囲む（107-110行目あたり）
   - コメント一覧エリアを `<div id="comments">` で囲む（94-102行目あたり）

2. `app/views/comments/_form.html.erb`:
   - フォームは通常の `form_with` のまま（`data` 属性の追加不要）

3. `app/controllers/comments_controller.rb` の `create` アクション:
   - 成功時: Turbo Stream で複数箇所を同時更新
     ```ruby
     render turbo_stream: [
       turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
       turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post })
     ]
     ```
   - 失敗時: フォームをエラーメッセージ付きで再表示
     ```ruby
     render turbo_stream: turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: @comment, post: @post }),
            status: :unprocessable_entity
     ```

**コミットメッセージ**: `Add Turbo Stream for comment creation to prevent page navigation`

### Phase 2: コメント編集のTurbo Frames対応

**目的**: コメント編集時の画面遷移を防ぎ、インライン編集を実現する

**変更内容**:

1. `app/views/comments/_comment.html.erb`:
   - 各コメントを `turbo_frame_tag dom_id(comment)` で囲む
   - 編集リンクに `data: { turbo_frame: dom_id(comment) }` を追加（フレーム内で編集フォームを読み込むため）
     ```erb
     <%= link_to "Edit", edit_comment_path(comment), data: { turbo_frame: dom_id(comment) } %>
     ```

2. `app/views/comments/edit.html.erb`:
   - 編集フォームを `turbo_frame_tag dom_id(@comment)` で囲む
   - パンくずリストは Turbo Frame の外に配置する

3. `app/controllers/comments_controller.rb` の `update` アクション:
   - 成功時: 更新されたコメントパーシャルを `turbo_frame_tag dom_id(@comment)` 内でレンダリング
   - 失敗時: エラーメッセージ付きの編集フォームをレンダリング

**コミットメッセージ**: `Add Turbo Frame for comment editing to prevent page navigation`

### Phase 3: コメント削除のTurbo Streams対応

**目的**: コメント削除時の画面遷移を防ぎ、DOM から要素を完全に削除する

**変更内容**:

1. `app/views/comments/_comment.html.erb`:
   - 削除ボタンは通常の `button_to` のまま（特別な `data` 属性は不要）

2. `app/controllers/comments_controller.rb` の `destroy` アクション:
   - 削除成功時: Turbo Stream の `remove` を使用して DOM から要素を削除
     ```ruby
     @comment.destroy
     render turbo_stream: turbo_stream.remove(dom_id(@comment))
     ```

**理由**: Turbo Stream の `remove` を使うことで、DOM から要素が完全に削除され、空フレームが残る問題を回避できる

**コミットメッセージ**: `Add Turbo Stream for comment deletion to prevent page navigation`

### Phase 4: コメント数の動的更新

**目的**: コメント投稿/削除時にコメント数を自動更新する

**変更内容**:

1. `app/views/posts/show.html.erb`:
   - コメント数表示部分に `id="comment_count_#{@post.id}"` を追加（88-90行目あたり）
     ```erb
     <span id="comment_count_<%= @post.id %>"><%= @post.comments.count %></span>
     ```

2. `app/controllers/comments_controller.rb`:
   - `create` アクションで、Phase 1 の Turbo Stream にコメント数更新を追加:
     ```ruby
     render turbo_stream: [
       turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
       turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post }),
       turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
     ]
     ```
   - `destroy` アクションで、Phase 3 の Turbo Stream にコメント数更新を追加:
     ```ruby
     render turbo_stream: [
       turbo_stream.remove(dom_id(@comment)),
       turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
     ]
     ```

**理由**: Turbo Stream に統一することで、技術スタックの一貫性が保たれ、サーバー側で正確なコメント数を計算できる

**コミットメッセージ**: `Add dynamic comment count update with Turbo Stream`

### Phase 5: テストの追加と修正

**目的**: 既存のテストを修正し、Turbo Streams/Frames の動作を検証する

**変更内容**:

1. `test/controllers/comments_controller_test.rb`:
   - `create` アクションのテスト:
     - リダイレクトのアサーションを削除
     - ステータスコードが 200 OK になることを確認
     - レスポンスに `<turbo-stream action="prepend" target="comments">` が含まれることを確認
     - レスポンスに `<turbo-stream action="replace" target="new_comment">` が含まれることを確認
     - レスポンスに `<turbo-stream action="update" target="comment_count_">` が含まれることを確認
     - 新規コメントの内容が含まれることを確認
   - `update` アクションのテスト:
     - リダイレクトのアサーションを削除
     - Turbo Frame レスポンスが返されることを確認
   - `destroy` アクションのテスト:
     - リダイレクトのアサーションを削除
     - レスポンスに `<turbo-stream action="remove">` が含まれることを確認
     - レスポンスに `<turbo-stream action="update" target="comment_count_">` が含まれることを確認

2. システムテストは作成しない:
   - ブラウザでの画面遷移抑止は手動テストで確認する
   - コントローラテストでレスポンス内容を十分に検証することで品質を担保する

**コミットメッセージ**: `Update tests for Turbo Stream/Frame comment operations`

## 技術的な詳細

### Turbo Frames の仕組み

- `turbo_frame_tag` で囲まれた領域は、独立したナビゲーションコンテキストを持つ
- Frame内のリンクやフォームは、同じ `id` を持つ Frame のみを更新する
- レスポンスに同じ `id` の Frame が含まれていれば、その部分だけが置き換えられる
- `data: { turbo_frame: "_top" }` を指定すると、ページ全体が更新される（デフォルト動作）

### コントローラーでの対応

```ruby
# Turbo Stream を使った例（コメント投稿）
def create
  @comment = @post.comments.build(comment_params)
  if @comment.save
    render turbo_stream: [
      turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
      turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post }),
      turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
    ]
  else
    render turbo_stream: turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: @comment, post: @post }),
           status: :unprocessable_entity
  end
end

# Turbo Stream を使った例（コメント削除）
def destroy
  @comment.destroy
  render turbo_stream: [
    turbo_stream.remove(dom_id(@comment)),
    turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
  ]
end
```

### Turbo Streams の主なアクション

- `prepend`: 指定した要素の先頭に追加
- `append`: 指定した要素の末尾に追加
- `replace`: 指定した要素を置き換え
- `update`: 指定した要素の内容を更新
- `remove`: 指定した要素を削除

### レイアウトの考慮事項

- Turbo Frame リクエストには、デフォルトで `turbo_rails/frame` レイアウトが適用される
- `edit.html.erb` のようなページでは、Turbo Frame 外の要素（パンくずリストなど）は通常のページ遷移時のみ表示される
- `turbo_frame_request?` ヘルパーで、Turbo Frame リクエストかどうかを判定できる

## 参考資料

- [Turbo Rails 公式ドキュメント](https://github.com/hotwired/turbo-rails)
- [Turbo Frames ガイド](https://turbo.hotwired.dev/handbook/frames)
- [Turbo Streams ガイド](https://turbo.hotwired.dev/handbook/streams)

## 注意事項

- 既存のテストが失敗する可能性があるため、各 Phase 後にテストを実行すること
- JavaScript が無効な環境では、従来通りページ遷移が発生する（フォールバック動作）
- Turbo Frame の `id` は一意である必要があるため、複数のコメント編集フォームが同時に開くことはできない（これは意図した動作）
