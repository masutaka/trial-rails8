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

- **Rails標準**: Action Cable と Solid Cable は Rails 8 に標準搭載
- **既存コードの活用**: 現在のTurbo Streamsコードを最小限の変更で拡張可能
- **シンプルな実装**: `broadcasts_to` を使うことで、モデルの変更が自動的にブロードキャストされる

### 現在の設定状況

- **config/cable.yml**: Solid Cableが設定済み（development/production）
- **db/cable_schema.rb**: Solid Cable用のスキーマが存在
- **app/channels/application_cable/**: Channel基盤が存在

## 実装手順

### Phase 1: コメントモデルにブロードキャスト設定を追加

**目的**: コメントの作成・更新・削除時に、該当記事を閲覧中のユーザーに自動的にTurbo Streamをブロードキャストする

**変更内容**:

1. `app/models/comment.rb` に1行追加:
   ```ruby
   broadcasts_to :post
   ```

**効果**: 作成・更新・削除が自動的に全ユーザーにブロードキャストされる

### Phase 2: 記事表示ページにTurbo Streamサブスクリプションを追加

**目的**: ユーザーが記事ページを閲覧している間、該当記事のコメント変更をリアルタイムで受信できるようにする

**変更内容**:

1. `app/views/posts/show.html.erb` のコメントセクション先頭（87行目あたり）に1行追加:
   ```erb
   <%= turbo_stream_from @post %>
   ```

**効果**: WebSocket接続を確立し、他ユーザーのコメント変更をリアルタイムで受信

### Phase 3: コメント数の更新をブロードキャスト

**目的**: コメント数の更新もリアルタイムで全ユーザーに反映

**変更内容**:

1. `app/controllers/comments_controller.rb` の `create` アクションに追加:
   ```ruby
   @comment.broadcast_update_to(
     @post,
     target: "comment_count_#{@post.id}",
     html: "(#{@post.comments.count})"
   )
   ```

2. `destroy` アクションにも同様に追加:
   ```ruby
   Turbo::StreamsChannel.broadcast_update_to(
     @post,
     target: "comment_count_#{@post.id}",
     html: "(#{@post.comments.count})"
   )
   ```

**注**: `update` アクションは変更不要（コメント数が変わらないため）

### Phase 4: テストの追加

**目的**: ブロードキャスト機能が正しく動作することを検証

**変更内容**:

1. `test/models/comment_test.rb` にブロードキャストのテストを追加:
   ```ruby
   include Turbo::Broadcastable::TestHelper

   test "broadcasts append on create" do
     assert_broadcasts_to(posts(:one)) do
       Comment.create!(post: posts(:one), user: users(:one), body: "New")
     end
   end

   test "broadcasts remove on destroy" do
     assert_broadcasts_to(comments(:one).post) { comments(:one).destroy }
   end
   ```

2. `test/controllers/comments_controller_test.rb` は既存のまま維持

## 考慮事項

- **パフォーマンス**: Solid Cable（SQLite）は小規模環境なら十分。同時接続数が多い場合はRedisへの移行を検討
- **エラーハンドリング**: WebSocket接続失敗時はTurboが自動的にHTTPにフォールバック。再接続も自動
- **JavaScript無効環境**: 従来通り手動リロードが必要（フォールバック動作）

## 参考資料

- [Turbo Streams - Broadcasting](https://turbo.hotwired.dev/handbook/streams#streaming-from-a-model)
- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html)
- [Turbo::Broadcastable API](https://github.com/hotwired/turbo-rails/blob/main/app/models/concerns/turbo/broadcastable.rb)
- [Solid Cable](https://github.com/rails/solid_cable)

## 注意事項

- Phase 1-2 でリアルタイム同期が動作開始。Phase 3-4 は補完的な実装
- 各Phase後にテストを実行し、既存機能が壊れていないことを確認
- 開発時は複数のブラウザウィンドウ/シークレットモードで動作確認
- 既存のアニメーションが動作しない場合は、必要に応じて調整
