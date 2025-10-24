# trial-rails8

[![CI](https://github.com/masutaka/trial-rails8/actions/workflows/ci.yml/badge.svg?branch=main)][CI]
[![CodeQL](https://github.com/masutaka/trial-rails8/actions/workflows/codeql.yml/badge.svg?branch=main)][CodeQL]
[![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/masutaka/trial-rails8)][CodeRabbit]
[![Ask DeepWiki](https://deepwiki.com/badge.svg)][DeepWiki]

[CI]: https://github.com/masutaka/trial-rails8/actions/workflows/ci.yml?query=branch%3Amain
[CodeQL]: https://github.com/masutaka/trial-rails8/actions/workflows/codeql.yml?query=branch%3Amain
[CodeRabbit]: https://www.coderabbit.ai/
[DeepWiki]: https://deepwiki.com/masutaka/trial-rails8

Rails 8 の学習用リポジトリです。

## 機能

このリポジトリは **Rails 8** の主要機能を学習するために作成されています。

### ブログ機能

記事の作成・編集・削除、予約投稿が可能なブログシステムです。

- **Active Job + Sidekiq**: 記事の予約投稿
  - [app/jobs/publish_post_job.rb](app/jobs/publish_post_job.rb) - 指定時刻に記事を自動公開
  - [config/sidekiq.yml](config/sidekiq.yml) - Sidekiq の設定
  - [config/initializers/sidekiq.rb](config/initializers/sidekiq.rb) - Redis 接続設定
- **Turbo Drive**: ページ遷移の高速化（アプリケーション全体でデフォルトで有効）
  - [app/javascript/application.js](app/javascript/application.js) - Turbo のインポート

#### コメント機能

ブログ記事へのコメント投稿・編集・削除機能です。

- **Turbo Streams**: 複数箇所の同時更新（フォームクリア + 一覧追加 + カウント更新）
  - [app/controllers/comments_controller.rb](app/controllers/comments_controller.rb) - コメント投稿・削除
- **Turbo Frames**: インライン編集（表示 ⇄ 編集フォームの切り替え）
  - [app/views/comments/edit.html.erb](app/views/comments/edit.html.erb) - 編集ページ
  - [app/views/comments/_comment.html.erb](app/views/comments/_comment.html.erb) - コメント部分テンプレート
- **Stimulus**: アニメーション効果
  - [app/javascript/controllers/comment_animation_controller.js](app/javascript/controllers/comment_animation_controller.js) - 追加/削除時のアニメーション

**詳細な設計思想:**
- [コメント機能で Turbo Streams と Turbo Frames を使い分ける理由](docs/why-comment-uses-turbo-streams-and-frames.md)

### 商品管理（Product）

商品情報の登録・編集機能です。

- **Action Text**: リッチテキストエディタ（商品説明）
  - [app/models/product.rb](app/models/product.rb) - `has_rich_text :description`
- **Active Storage**: ファイルアップロード（商品画像）
  - [app/models/product.rb](app/models/product.rb) - `has_one_attached :featured_image`

### リアルタイムチャット

WebSocket を使ったリアルタイムチャット機能です。

- **Action Cable + Solid Cable**: WebSocket によるリアルタイム通信
  - [app/channels/chat_channel.rb](app/channels/chat_channel.rb) - チャットチャンネルの実装
  - [app/javascript/controllers/chat_controller.js](app/javascript/controllers/chat_controller.js) - Stimulus でチャット UI を制御
  - [config/cable.yml](config/cable.yml) - Solid Cable の設定

### ユーザー認証

ログイン・ログアウト機能です。

- **authenticate_by**: パスワード認証の新しい API
  - [app/controllers/sessions_controller.rb](app/controllers/sessions_controller.rb)
- **rate_limit**: レート制限の組み込みサポート
  - [app/controllers/sessions_controller.rb](app/controllers/sessions_controller.rb)
- **has_secure_password (BCrypt)**: パスワードのハッシュ化

## セットアップ

### 前提条件

- Docker と Docker Compose がインストールされていること

### 手順

1. MySQL と Redis コンテナを起動:

```bash
docker compose up -d
```

2. 依存関係のインストール、データベース作成、サーバー起動:

```bash
bin/setup
```

3. （必要に応じて）サンプルデータの投入:

```bash
bin/rails db:seed
```

http://localhost:3000 から、アプリケーションにアクセスできます。

### MySQL と Redis コンテナの管理

- コンテナの起動: `docker compose up -d`
- コンテナの停止: `docker compose down`
- データの削除（完全リセット）: `docker compose down -v`

## Active Job の監視

開発環境では、Active Job の実行状況を Web UI で確認できます。

http://localhost:3000/sidekiq

Sidekiq Web UI を使用して、以下の情報を確認できます：

- ジョブの実行状態（処理中・キュー待ち・リトライ・スケジュール済み・完了・失敗）
- キューのリアルタイム統計（処理済み・失敗・リトライ数）
- Redis の接続情報とメモリ使用量
- 失敗したジョブの手動リトライ
- スケジュールされたジョブの確認

## データベース構造

[Liam ERD](https://liambx.com/) でデータベースの ER 図をインタラクティブに閲覧できます。

### メインアプリケーション

[ERDを表示](https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/schema.rb)

アプリケーションのコアテーブル（users、posts、comments など）の構造とリレーションシップを確認できます。

### Solid Cable（Action Cable）

[ERDを表示](https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/cable_schema.rb)

Action Cable の内部構造（WebSocketメッセージ、チャンネル、ブロードキャストなど）を確認できます。

## 参考資料

### Rails ガイド（日本語）

- [Active Job の基礎](https://railsguides.jp/active_job_basics.html)
- [Action Cable の概要](https://railsguides.jp/action_cable_overview.html)
- [Action Text の概要](https://railsguides.jp/action_text_overview.html)
- [Active Storage の概要](https://railsguides.jp/active_storage_overview.html)
- [Rails のキャッシュ機構](https://railsguides.jp/caching_with_rails.html)
- [セキュリティガイド](https://railsguides.jp/security.html) - has_secure_password など

### Hotwire（Turbo & Stimulus）

- [Hotwire 公式サイト](https://hotwired.dev/)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
  - [Turbo Drive](https://turbo.hotwired.dev/handbook/drive) - ページ遷移の高速化
  - [Turbo Frames](https://turbo.hotwired.dev/handbook/frames) - 部分的なページ更新
  - [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) - 複数箇所の同時更新
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)

### Solid Trifecta（Rails 8 の新機能）

- [Solid Queue（GitHub）](https://github.com/rails/solid_queue) - データベースベースの Active Job バックエンド（このリポジトリでは未使用）
- [Solid Cache（GitHub）](https://github.com/rails/solid_cache) - データベースベースのキャッシュストア（このリポジトリでは未使用）
- [Solid Cable（GitHub）](https://github.com/rails/solid_cable) - データベースベースの Action Cable アダプター

### Background Jobs

- [Sidekiq（GitHub）](https://github.com/sidekiq/sidekiq) - Redis ベースのバックグラウンドジョブ処理
- [Sidekiq Wiki](https://github.com/sidekiq/sidekiq/wiki) - Sidekiq の詳細なドキュメント
