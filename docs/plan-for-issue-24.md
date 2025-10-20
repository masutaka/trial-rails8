# Issue #24: コメントのリアルタイム同期機能を実装する - 実装計画

## 概要

現在、コメントの投稿/編集/削除時に画面遷移は抑止されているが、他のユーザーがブラウザをリロードしないと新しいコメントを閲覧できない。リアルタイム同期機能を実装し、複数のユーザーが同じ記事を閲覧している際に、自動的にコメントの変更が反映されるようにする。

## 現状の問題点

- ユーザーAとユーザーBが同じ記事のコメントを見ている
- ユーザーBがコメントを投稿しても、ユーザーAには通知されない
- ユーザーAは手動でページをリロードする必要がある
- コメントの編集・削除も同様に、他のユーザーにリアルタイムで反映されない
- コメント数も自動的に更新されない

## 実装方針

**Turbo Streams over WebSocket (Action Cable) を使用**

### 技術スタック

- **Action Cable**: WebSocket接続の確立と管理（Rails 8標準、Solid Cableを使用）
- **Turbo Streams**: サーバーからクライアントへのDOM更新の配信
- **broadcasts_to**: モデルレベルでのブロードキャスト設定

### なぜこのアプローチか

1. **Rails標準**: Action Cable と Solid Cable は Rails 8 に標準搭載
2. **既存コードの活用**: 現在のTurbo Streamsコードを最小限の変更で拡張可能
3. **リアルタイム性**: WebSocketによる双方向通信で即座に反映
4.゙シンプルな実装**: `broadcasts_to` を使うことで、モデルの変更が自動的にブロードキャストされる
5. **スケーラビリティ**: Solid Cable（SQLite）は開発・小規模本番環境で十分。将来Redisに切り替えも可能

### 現在の設定状況

- **config/cable.yml**: Solid Cableが設定済み（development/production）
- **db/cable_schema.rb**: Solid Cable用のスキーマが存在
- **app/channels/application_cable/**: Channel基盤が存在

## 実装手順

### Phase 1: コメントモデルにブロードキャスト設定を追加

**目的**: コメントの作成・更新・削除時に、該当記事を閲覧中のユーザーに自動的にTurbo Streamをブロードキャストする

**変更内容**:

1. `app/models/comment.rb`:
   - `broadcasts_to` を追加してPostに対してブロードキャスト
   ```ruby
   class Comment < ApplicationRecord
     belongs_to :post
     belongs_to :user

     validates :body, presence: true, length: { minimum: 1, maximum: 10000 }

     # コメントの変更を該当Postのストリームにブロードキャスト
     broadcasts_to :post
   end
   ```

**効果**:
- コメント作成時: `broadcast_append_to post, target: "comments"` が自動実行
- コメント更新時: `broadcast_replace_to post` が自動実行（コメント全体を置換）
- コメント削除時: `broadcast_remove_to post` が自動実行

**コミットメッセージ**: `Add broadcasts_to for real-time comment synchronization`

### Phase 2: 記事表示ページにTurbo Streamサブスクリプションを追加

**目的**: ユーザーが記事ページを閲覧している間、該当記事のコメント変更をリアルタイムで受信できるようにする

**変更内容**:

1. `app/views/posts/show.html.erb`:
   - コメントセクションの先頭（87行目あたり）に `turbo_stream_from` を追加
   ```erb
   <!-- コメントセクション -->
   <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
     <%= turbo_stream_from @post %>

     <h2 class="text-xl font-bold text-gray-900 mb-4">
       コメント
       <span id="comment_count_<%= @post.id %>" class="text-sm font-normal text-gray-500">(<%= @post.comments.count %>)</span>
     </h2>
     <!-- 以下既存のコード -->
   ```

**効果**:
- ページ表示時にAction Cable経由でWebSocket接続が確立される
- 該当PostのTurbo Streamチャネルにサブスクライブ
- 他のユーザーがコメントを作成・更新・削除すると、リアルタイムでDOM更新を受信

**技術詳細**:
- `turbo_stream_from @post` は内部的に `turbo_stream_from "post:#{@post.id}"` のような署名付きストリーム名を生成
- セキュリティ: ストリーム名は暗号化署名されるため、改ざん不可

**コミットメッセージ**: `Subscribe to post turbo stream for real-time updates`

### Phase 3: コントローラーのブロードキャスト処理を調整

**目的**: コメント数の更新もリアルタイムで全ユーザーに反映されるようにする

**変更内容**:

1. `app/controllers/comments_controller.rb` の `create` アクション:
   - 現在のTurbo Stream レスポンス（ローカル更新用）はそのまま維持
   - コメント数更新のブロードキャストを追加
   ```ruby
   def create
     # @post is already loaded by ensure_post_published
     @comment = @post.comments.build(comment_params)
     @comment.user = Current.user

     if @comment.save
       # broadcasts_to により、コメント追加は自動的に全ユーザーにブロードキャストされる
       # コメント数も全ユーザーに更新
       @comment.broadcast_update_to(
         @post,
         target: "comment_count_#{@post.id}",
         html: "(#{@post.comments.count})"
       )

       # 投稿したユーザー自身への即座のレスポンス
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
   ```

2. `app/controllers/comments_controller.rb` の `destroy` アクション:
   - 削除後のコメント数更新を全ユーザーにブロードキャスト
   ```ruby
   def destroy
     @post = @comment.post
     @comment.destroy

     # broadcasts_to により、コメント削除は自動的に全ユーザーにブロードキャストされる
     # コメント数も全ユーザーに更新
     Turbo::StreamsChannel.broadcast_update_to(
       @post,
       target: "comment_count_#{@post.id}",
       html: "(#{@post.comments.count})"
     )

     # 削除したユーザー自身への即座のレスポンス
     render turbo_stream: [
       turbo_stream.remove(helpers.dom_id(@comment)),
       turbo_stream.update("comment_count_#{@post.id}", "(#{@post.comments.count})")
     ]
   end
   ```

3. `app/controllers/comments_controller.rb` の `update` アクション:
   - `broadcasts_to` により更新は自動的にブロードキャストされるため、変更不要
   - ただし、編集したユーザー自身への即座のレスポンスは維持

**理由**:
- `broadcasts_to` はコメントの作成・更新・削除を自動的にブロードキャストするが、コメント数は別途手動でブロードキャストする必要がある
- 投稿/削除したユーザー自身には、即座にレスポンスを返すことでUXを向上

**コミットメッセージ**: `Broadcast comment count updates to all users in real-time`

### Phase 4: コメント追加時のアニメーション対応（オプション）

**目的**: 他のユーザーが投稿したコメントが突然表示されて驚かせないよう、視覚的なフィードバックを追加

**変更内容**:

1. Stimulus コントローラー（既存の `comment-animation_controller.js`）の活用:
   - 既存のアニメーション処理がブロードキャストでも動作するか確認
   - 必要に応じて調整

2. `app/views/comments/_comment.html.erb`:
   - 既にアニメーション用のdata属性が設定されているため、変更不要の可能性が高い

**注意**: 既存のアニメーションコードを確認してから実装を決定

**コミットメッセージ**: `Ensure animations work for broadcasted comments` (必要な場合のみ)

### Phase 5: テストの追加

**目的**: ブロードキャスト機能が正しく動作することを検証

**変更内容**:

1. `test/models/comment_test.rb`:
   - ブロードキャストのテストを追加
   ```ruby
   require "test_helper"

   class CommentTest < ActiveSupport::TestCase
     include Turbo::Broadcastable::TestHelper

     test "broadcasts append on create" do
       post = posts(:one)
       user = users(:one)

       assert_broadcasts_to(post) do
         Comment.create!(post: post, user: user, body: "New comment")
       end
     end

     test "broadcasts remove on destroy" do
       comment = comments(:one)
       post = comment.post

       assert_broadcasts_to(post) do
         comment.destroy
       end
     end

     test "broadcasts replace on update" do
       comment = comments(:one)
       post = comment.post

       assert_broadcasts_to(post) do
         comment.update!(body: "Updated comment")
       end
     end
   end
   ```

2. `test/controllers/comments_controller_test.rb`:
   - 既存のテストは維持（ローカルレスポンスの検証）
   - 必要に応じてブロードキャストのアサーションを追加

**コミットメッセージ**: `Add tests for comment broadcasting`

## 技術的な詳細

### broadcasts_to の仕組み

```ruby
broadcasts_to :post
```

これは以下のコールバックと同等:

```ruby
after_create_commit do
  broadcast_append_to post, target: "comments"
end

after_update_commit do
  broadcast_replace_to post
end

after_destroy_commit do
  broadcast_remove_to post
end
```

### Turbo Stream の配信フロー

1. **コメント作成時**:
   - ユーザーBがコメントを投稿
   - `Comment#save` が成功
   - `after_create_commit` コールバックが発火
   - `broadcast_append_to post, target: "comments"` が実行
   - Action Cable経由で該当Postのチャネルにサブスクライブしている全クライアントに配信
   - ユーザーAのブラウザで `<turbo-stream action="append" target="comments">` が受信され、DOMが更新される

2. **コメント削除時**:
   - ユーザーBがコメントを削除
   - `Comment#destroy` が成功
   - `after_destroy_commit` コールバックが発火
   - `broadcast_remove_to post` が実行
   - 全クライアントに配信され、該当コメントがDOMから削除される

### WebSocket接続

- **開発環境**: Solid Cable（SQLite）を使用
- **本番環境**: Solid Cable（SQLite）を使用（小規模なら十分）
- **スケーリング**: 必要に応じて `config/cable.yml` を変更してRedisに切り替え可能

### セキュリティ

- ストリーム名は暗号化署名される（`turbo_stream_from @post`）
- カスタムチャネルで認証・認可ロジックを追加可能（今回は不要）
- 公開記事のコメントなので、追加の認証は不要

## 考慮事項

### パフォーマンス

- **WebSocket接続数**: 各ユーザーが記事ページを開くとWebSocket接続を確立
- **Solid Cable**: SQLiteベースなので、同時接続数が多い場合はRedisへの移行を検討
- **ブロードキャスト頻度**: コメント作成・更新・削除時のみなので、負荷は低い

### エラーハンドリング

- **WebSocket接続失敗時**: Turbo は自動的にフォールバックし、通常のHTTPリクエストとして動作
- **ネットワーク切断時**: Action Cable は自動的に再接続を試みる
- **ブロードキャスト失敗時**: ローカルレスポンスは正常に返されるため、投稿したユーザーには影響なし

### フォールバック動作

- JavaScript無効環境: 従来通り手動リロードが必要
- WebSocket非対応ブラウザ: 極めて稀（現代のブラウザはすべて対応）

## 参考資料

- [Turbo Streams - Broadcasting](https://turbo.hotwired.dev/handbook/streams#streaming-from-a-model)
- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html)
- [Turbo::Broadcastable API](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb)
- [Solid Cable](https://github.com/rails/solid_cable)

## 注意事項

- Phase 1 と Phase 2 を実装後、すぐにリアルタイム同期が動作する
- Phase 3 は、コメント数の同期を追加する補完的な実装
- Phase 4 は完全にオプション（既存のアニメーションが動作する可能性が高い）
- 各 Phase 後にテストを実行し、既存機能が壊れていないことを確認すること
- 開発時は複数のブラウザウィンドウ/シークレットモードで動作確認すること
