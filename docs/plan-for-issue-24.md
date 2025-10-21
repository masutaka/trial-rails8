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

### Phase 1: ブロードキャストのテストと実装（Red→Green）

**目的**: TDD原則に従い、コメント変更とコメント数を全ユーザーにブロードキャスト

**変更内容**:

1. `test/models/comment_test.rb` に `include Turbo::Broadcastable::TestHelper` と、作成・削除・コメント数のブロードキャストテストを追加（Red）

2. `app/models/comment.rb` に以下を追加:
   - `broadcasts_to :post`
   - `after_create_commit` / `after_destroy_commit` でコメント数をブロードキャスト

3. `app/views/posts/_comment_count.html.erb` を新規作成（コメント数表示用パーシャル）

**効果**: テストが成功（Green）、作成・更新・削除とコメント数が自動ブロードキャスト

### Phase 2: DOM構造の調整

**目的**: `broadcasts_to` のターゲットとDOM構造を一致させる

**変更内容**:

1. `app/views/posts/show.html.erb` の `div#comments` を `<div id="comments" class="space-y-2 mb-6">` に変更し、直下のdivを削除

**効果**: `broadcasts_to` が `div#comments` の直下に正しく追加される

### Phase 3: 記事表示ページにTurbo Streamサブスクリプションを追加

**目的**: WebSocket接続を確立し、リアルタイム更新を受信

**変更内容**:

1. `app/views/posts/show.html.erb` のコメントセクション先頭に `<%= turbo_stream_from @post %>` を追加

**効果**: 他ユーザーのコメント変更をリアルタイムで受信

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

- Phase 1 でTDDサイクル（Red→Green）を実践
- Phase 2-3 でリアルタイム同期が動作開始
- 各Phase後にテストを実行し、既存機能が壊れていないことを確認
- 開発時は複数のブラウザウィンドウ/シークレットモードで動作確認
- 既存のアニメーションが動作しない場合は、必要に応じて調整
