# Issue #21: コメントの投稿/編集/削除での画面遷移を止める - 実装計画

## 概要

コメントの投稿/編集/削除時に、ページ全体がリロードされて記事の先頭に遷移してしまう問題を解決し、ユーザーが現在の位置を保持したままコメント操作を完了できるようにする。

## 現状の問題点

- コメントの投稿時: `CommentsController#create` で `redirect_to post_url(@post)` が実行され、ページ全体が遷移する（app/controllers/comments_controller.rb:13）
- コメントの編集時: `GET /comments/:id/edit` で別ページに遷移し、更新後に `redirect_to post_url(@comment.post)` が実行される（app/controllers/comments_controller.rb:26）
- コメントの削除時: `CommentsController#destroy` で `redirect_to post_url(@post)` が実行される（app/controllers/comments_controller.rb:37）
- 本文が長い記事では、操作後に記事の先頭に戻ってしまい、ユーザー体験が悪い

## 実装方針

**Turbo Frames** を採用する

### Turbo Framesを選択する理由

1. **シンプルな実装**: 画面遷移を伴わない部分更新に最適
2. **状態管理不要**: JavaScriptで複雑な状態管理をする必要がない
3. **Rails標準**: Rails 7以降で標準搭載されている（既に `@hotwired/turbo-rails` がインポートされている - app/javascript/application.js:2）
4. **段階的な実装**: 各操作（投稿/編集/削除）を個別に段階的に実装できる
5. **テスト容易性**: Railsのテストツールで十分にテスト可能

### Turbo Streamsを使わない理由

- Turbo Streamsはリアルタイム更新や複数箇所の同時更新に適している
- 今回は単一のコメント操作のみであり、Turbo Framesで十分対応可能
- よりシンプルな実装で保守性が高い

## 実装手順

### Phase 1: コメント投稿のTurbo Frames対応

**目的**: 新規コメント投稿時の画面遷移を防ぐ

**変更内容**:

1. `app/views/posts/show.html.erb`:
   - コメントフォームエリアを `turbo_frame_tag "new_comment"` で囲む（107-110行目あたり）
   - コメント一覧エリアを `turbo_frame_tag "comments"` で囲む（94-102行目あたり）

2. `app/views/comments/_form.html.erb`:
   - フォームに `data: { turbo_frame: "comments" }` を追加（投稿成功時にコメント一覧を更新するため）

3. `app/controllers/comments_controller.rb` の `create` アクション:
   - 成功時: コメント一覧とフォームをレンダリングする Turbo Frame レスポンスを返す
   - 失敗時: エラーメッセージ付きのフォームを `turbo_frame_tag "new_comment"` 内でレンダリング

**コミットメッセージ**: `Add Turbo Frame for comment creation to prevent page navigation`

### Phase 2: コメント編集のTurbo Frames対応

**目的**: コメント編集時の画面遷移を防ぐ

**変更内容**:

1. `app/views/comments/_comment.html.erb`:
   - 各コメントを `turbo_frame_tag dom_id(comment)` で囲む

2. `app/views/comments/edit.html.erb`:
   - 編集フォームを `turbo_frame_tag dom_id(@comment)` で囲む
   - パンくずリストは Turbo Frame の外に配置する

3. `app/controllers/comments_controller.rb` の `update` アクション:
   - 成功時: 更新されたコメントパーシャルを `turbo_frame_tag dom_id(@comment)` 内でレンダリング
   - 失敗時: エラーメッセージ付きの編集フォームをレンダリング

**コミットメッセージ**: `Add Turbo Frame for comment editing to prevent page navigation`

### Phase 3: コメント削除のTurbo Frames対応

**目的**: コメント削除時の画面遷移を防ぐ

**変更内容**:

1. `app/views/comments/_comment.html.erb`:
   - 削除ボタンに `data: { turbo_frame: dom_id(comment) }` を追加（既にPhase 2でコメント全体がTurbo Frame内にある）

2. `app/controllers/comments_controller.rb` の `destroy` アクション:
   - 削除成功時: 空の Turbo Frame を返す（`render turbo_stream: turbo_stream.remove(dom_id(@comment))` の代わりに、Turbo Frameで空のコンテンツを返す）
   - または、Turbo Streamsの `remove` アクションを使用する（こちらの方がシンプル）

**注意**: 削除時は Turbo Streams の `remove` を使う方が自然なため、この Phase では Turbo Streams も併用する

**コミットメッセージ**: `Add Turbo Stream for comment deletion to prevent page navigation`

### Phase 4: コメント数の動的更新

**目的**: コメント投稿/削除時にコメント数を自動更新する

**変更内容**:

1. `app/views/posts/show.html.erb`:
   - コメント数表示部分を `turbo_frame_tag "comment_count"` または `id="comment_count"` で識別可能にする（88-90行目あたり）

2. `app/controllers/comments_controller.rb`:
   - `create` と `destroy` アクションで、Turbo Streams を使ってコメント数を更新する
   - または、JavaScript Stimulusコントローラーでクライアント側でカウントを更新する

**コミットメッセージ**: `Add dynamic comment count update with Turbo`

### Phase 5: テストの追加と修正

**目的**: 既存のテストを修正し、Turbo Frames の動作を検証する

**変更内容**:

1. `test/controllers/comments_controller_test.rb`:
   - リダイレクトのアサーションを、Turbo Frame レスポンスのアサーションに変更
   - ステータスコードが 200 OK になることを確認
   - レスポンスに期待する Turbo Frame が含まれることを確認

2. システムテストの追加（必要に応じて）:
   - コメント投稿後、ページが遷移せずコメントが表示されることを確認
   - コメント編集後、ページが遷移せずコメントが更新されることを確認
   - コメント削除後、ページが遷移せずコメントが削除されることを確認

**コミットメッセージ**: `Update tests for Turbo Frame comment operations`

## 技術的な詳細

### Turbo Frames の仕組み

- `turbo_frame_tag` で囲まれた領域は、独立したナビゲーションコンテキストを持つ
- Frame内のリンクやフォームは、同じ `id` を持つ Frame のみを更新する
- レスポンスに同じ `id` の Frame が含まれていれば、その部分だけが置き換えられる
- `data: { turbo_frame: "_top" }` を指定すると、ページ全体が更新される（デフォルト動作）

### コントローラーでの対応

```ruby
# 成功時の例
def create
  if @comment.save
    render partial: "comments/comment", locals: { comment: @comment },
           layout: false,
           formats: [:html]
  else
    render :new, status: :unprocessable_entity
  end
end
```

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
