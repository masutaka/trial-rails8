# Issue #13: 通知機能

## 概要

- **IssueURL**: https://github.com/masutaka/trial-rails8/issues/13
- **タイトル**: 通知機能
- **ラベル**: enhancement

## 目的

記事が公開されたときに全ユーザーに通知する機能を実装します。通知はブラウザのタブをリロードせずにリアルタイムで状態が変わるようにします。

## 現状分析

### 既存の実装

- **Post モデル** (`app/models/post.rb`)
  - 予約投稿機能が実装済み
  - `PublishPostJob` で記事が公開される (`published: true` に更新)

- **User モデル** (`app/models/user.rb`)
  - 基本的なユーザー認証機能あり
  - `has_many :posts`, `has_many :sessions`

- **Turbo Streams と Stimulus が利用可能**（Rails 8 標準）

### 技術選択: Turbo Streams

Issue には「WebSocket (Action Cable) か JavaScript で実装するか決める必要がある」とありますが、**Turbo Streams** を採用します。

**実装難易度の比較:**
- **Turbo Streams**: サーバー側で HTML を生成するだけ、JavaScript ほぼ不要、Rails の標準テストで書ける（難易度: 低）
- **Action Cable**: チャンネル定義、JavaScript で DOM 操作、チャンネルテストが複雑（難易度: 中〜高）

**結論**: 実装難易度が低い **Turbo Streams** を採用します。

## 実装する機能

### 1. データベース設計

#### Notification テーブル

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | integer | NO | - | 主キー |
| user_id | integer | NO | - | 通知先ユーザー（外部キー） |
| post_id | integer | NO | - | 公開された記事（外部キー） |
| read | boolean | NO | false | 既読フラグ |
| created_at | datetime | NO | - | 作成日時 |
| updated_at | datetime | NO | - | 更新日時 |

#### インデックス

- `[user_id, read, created_at]`: 未読通知の取得とソート
- `[user_id, created_at]`: 全通知の日時ソート
- `post_id`: 記事削除時の cascade delete

#### 外部キー

- `user_id` → `users.id` (cascade delete)
- `post_id` → `posts.id` (cascade delete)

### 2. Notification モデル

#### 関連

- `belongs_to :user`
- `belongs_to :post`

#### スコープ

- `unread`: 未読通知（`read: false`）
- `recent`: 最近の通知（`order(created_at: :desc)`）

#### メソッド

- `mark_as_read!`: 通知を既読にする

#### クラスメソッド

- `unread_count_for(user)`: 指定ユーザーの未読通知数を取得

#### コールバック（Turbo Streams）

- `after_create_commit :broadcast_notification`
  - 通知作成後、Turbo Streams でユーザーに通知バッジを更新
  - `Turbo::StreamsChannel.broadcast_update_to` を使用

- `after_update_commit :broadcast_badge_update, if: :saved_change_to_read?`
  - 既読状態変更後、Turbo Streams でバッジを更新

### 3. User モデルの拡張

#### 関連

- `has_many :notifications, dependent: :destroy`

### 4. Post モデルの拡張

#### 関連

- `has_many :notifications, dependent: :destroy`

#### コールバック

- `after_commit :notify_all_users, if: :just_published?`
  - 記事が公開されたタイミング（`published` が `false` → `true` に変更、または新規作成時に `published: true`）で全ユーザーに通知を作成
  - `NotifyPublicationJob` をエンキュー

#### メソッド

- `just_published?`: 今回の更新で公開されたかを判定
  - `saved_change_to_published?` と `published?` を使用

### 5. NotifyPublicationJob

- `queue_as :default`
- 引数: `post_id`
- 処理:
  1. 記事を取得
  2. 記事の作成者以外の全ユーザーに通知を作成
  3. 通知作成時のコールバックで自動的に Turbo Streams がブロードキャストされる

### 6. ルーティング

```ruby
scope :notifications do
  patch ':id/mark_as_read', to: 'notifications#mark_as_read', as: :mark_as_read_notification
  patch 'mark_all_as_read', to: 'notifications#mark_all_as_read', as: :mark_all_as_read_notifications
end
```

### 7. NotificationsController

#### 認証

- `before_action :require_authentication`: すべてのアクションで認証必須

#### mark_as_read

- 指定された通知を既読にする
- 更新時のコールバックで自動的に Turbo Streams がブロードキャストされる
- Turbo Frame でレスポンス

#### mark_all_as_read

- ユーザーの全未読通知を既読にする
- Turbo Streams でバッジとドロップダウンを更新

### 8. ビューの更新

#### レイアウト（application.html.erb）

- **Turbo Streams 購読**: `<%= turbo_stream_from "notifications_#{Current.user.id}" %>`
- **通知アイコン**: ヘッダー右上に配置
- **未読バッジ**: 未読数を表示（`id="notification_badge"`）
- **ドロップダウン**: 通知一覧を表示（`id="notification_dropdown"`）
  - 記事タイトル、公開時刻
  - 既読/未読の状態
  - 「すべて既読にする」ボタン

#### パーシャル

- `_badge.html.erb`: 未読バッジの表示
- `_dropdown.html.erb`: ドロップダウンの内容（最新20件を表示）
- `_notification.html.erb`: 個別の通知アイテム

## TDD アプローチに基づく実装手順

t-wada氏の推奨するTDDアプローチに従い、「テストを書く → 実装する → リファクタリング」のサイクルを繰り返します。

### Phase 1: マイグレーション

1. **マイグレーションファイルの作成**
   ```bash
   bin/rails generate model Notification user:references post:references read:boolean
   ```

2. **マイグレーションファイルの編集**
   - `read` カラムに `default: false, null: false` を追加
   - インデックスの追加:
     - `add_index :notifications, [:user_id, :read, :created_at]`
     - `add_index :notifications, [:user_id, :created_at]`
     - `add_index :notifications, :post_id`
   - 外部キー制約の追加（cascade delete）

3. **マイグレーション実行**
   ```bash
   bin/rails db:migrate
   bin/rails db:migrate RAILS_ENV=test
   ```

### Phase 2: モデル（TDD）

#### 1. Notification モデル

1. **`unread` スコープ（TDD）**
   - `test/models/notification_test.rb` に `unread` スコープのテストを追加
   - `unread` スコープを実装
   - テストが通ることを確認

2. **`recent` スコープ（TDD）**
   - `test/models/notification_test.rb` に `recent` スコープのテストを追加
   - `recent` スコープを実装
   - テストが通ることを確認

3. **`mark_as_read!` メソッド（TDD）**
   - `test/models/notification_test.rb` に `mark_as_read!` のテストを追加
   - `mark_as_read!` メソッドを実装
   - テストが通ることを確認

4. **`unread_count_for` クラスメソッド（TDD）**
   - `test/models/notification_test.rb` に `unread_count_for` のテストを追加
   - `unread_count_for` クラスメソッドを実装
   - テストが通ることを確認

5. **Turbo Streams ブロードキャスト（TDD）**
   - `test/models/notification_test.rb` にブロードキャストのテストを追加
     - 通知作成時にブロードキャストされること
     - 既読更新時にブロードキャストされること
   - コールバックを実装
   - テストが通ることを確認

#### 2. Post モデル

1. **`has_many :notifications` アソシエーションの追加**
   - `app/models/post.rb` に `has_many :notifications, dependent: :destroy` を追加
   - 既存のテストが通ることを確認

2. **`just_published?` メソッド（TDD）**
   - `test/models/post_test.rb` に `just_published?` のテストを追加
   - `just_published?` メソッドを実装
   - テストが通ることを確認

3. **通知作成コールバック（TDD）**
   - `test/models/post_test.rb` に通知作成のテストを追加
     - 記事公開時に `NotifyPublicationJob` がエンキューされること
     - 下書き保存時はエンキューされないこと
   - `after_commit :notify_all_users` コールバックを実装
   - テストが通ることを確認

### Phase 3: Job（TDD）

1. **NotifyPublicationJob のテスト作成**
   ```bash
   bin/rails generate job NotifyPublication
   ```
   - `test/jobs/notify_publication_job_test.rb` にテストを記述
   - 正常系: 全ユーザー（作成者除く）に通知が作成されること
   - 異常系: 記事が見つからない場合

2. **NotifyPublicationJob の実装**
   - ジョブロジックの実装
   - テストが通ることを確認

### Phase 4: ルーティングとコントローラー（TDD）

1. **ルーティングのテスト作成と実装（TDD）**
   - `test/controllers/notifications_routing_test.rb` にルーティングテストを記述
     - `PATCH /notifications/:id/mark_as_read` が `notifications#mark_as_read` にルーティングされること
     - `PATCH /notifications/mark_all_as_read` が `notifications#mark_all_as_read` にルーティングされること
   - `config/routes.rb` にルーティングを追加
   - テストが通ることを確認

2. **NotificationsController のテスト作成**
   ```bash
   bin/rails generate controller Notifications
   ```
   - `test/controllers/notifications_controller_test.rb` にテストを記述
   - 認証チェック: 未認証ユーザーはアクセスできないこと
   - `mark_as_read`: 通知が既読になること
   - `mark_all_as_read`: 全通知が既読になること

3. **NotificationsController の実装**
   - `before_action :require_authentication` で認証チェック
   - コントローラーロジックの実装
   - テストが通ることを確認

### Phase 5: ビュー

1. **パーシャルの作成**
   - `app/views/notifications/_badge.html.erb`: 未読バッジ
   - `app/views/notifications/_dropdown.html.erb`: ドロップダウン（最新20件）
   - `app/views/notifications/_notification.html.erb`: 個別通知

2. **レイアウトの更新**
   - `app/views/layouts/application.html.erb` に通知アイコンを追加
   - `turbo_stream_from` で購読
   - 未読バッジとドロップダウンの表示

3. **Stimulus コントローラー**
   - ドロップダウンの表示切り替え
   - Turbo Streams が DOM 更新を自動処理

## テスト戦略

TDDアプローチに従い、以下の順序でテストを記述します：

### 1. モデルテスト

- **Notification モデル**:
  - スコープのテスト（`unread`, `recent`）
  - `mark_as_read!` メソッドのテスト
  - `unread_count_for` クラスメソッドのテスト
  - Turbo Streams ブロードキャストのテスト
- **Post モデル**:
  - `just_published?` メソッドのテスト
  - 通知作成コールバックのテスト（ジョブのエンキュー確認）

### 2. Jobテスト

- **NotifyPublicationJob**:
  - 通知作成の正常系
  - 異常系（記事が見つからない）

### 3. ルーティングとコントローラーテスト

- **ルーティング**:
  - `PATCH /notifications/:id/mark_as_read` が `notifications#mark_as_read` にルーティングされること
  - `PATCH /notifications/mark_all_as_read` が `notifications#mark_all_as_read` にルーティングされること
- **NotificationsController**:
  - 認証チェック: 未認証ユーザーはアクセスできないこと
  - `mark_as_read`: 通知が既読になること
  - `mark_all_as_read`: 全通知が既読になること

## セキュリティ考慮事項

### 1. 認証と認可

- **認証**: `before_action :require_authentication` ですべてのアクションで認証必須
- **認可**: 通知の既読操作は自分の通知のみ可能（`Current.user.notifications` で範囲を限定）
- **Turbo Streams**: ユーザーごとのストリーム分離（`turbo_stream_from "notifications_#{user.id}"`）

### 2. CSRF 対策

- Rails の標準機能（`protect_from_forgery`）で対応

### 3. レート制限

- 通知の既読操作の頻度制限（将来的に検討）

### 4. N+1 クエリ対策

- ドロップダウン表示時: `includes(:post)`
- 未読数カウント: 現時点は `Notification.unread_count_for(user)` でカウントクエリ、将来的に `counter_cache` を検討

### 5. XSS 対策

- 記事タイトルのエスケープ処理（Rails の自動エスケープ）

## パフォーマンス最適化

### 1. データベース

- インデックス: `[user_id, read, created_at]`, `[user_id, created_at]`, `post_id`
- N+1 クエリ対策: `includes(:post)`
- 古い通知の削除: 定期的なクリーンアップ（将来的に実装）

### 2. Turbo Streams

- Redis を使用（Production環境で推奨）
- 接続数の監視

### 3. キャッシュ

- 未読数のキャッシュ（将来的に `counter_cache` または Redis を検討）

## 参考資料

- [Turbo Streams - Hotwire](https://turbo.hotwired.dev/handbook/streams)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [TDD（テスト駆動開発）- t-wada](https://www.youtube.com/watch?v=Q-FJ3XmFlT8)
- [Rails Testing Guide](https://railsguides.jp/testing.html)
