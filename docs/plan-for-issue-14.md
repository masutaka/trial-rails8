# Issue #14: フォロー機能 - 実装計画

## 概要

現在のアプリケーションには、ユーザー間の関係性を表現する機能がありません。この Issue では、ユーザーが他のユーザーをフォローできる機能を実装します。

**前提条件**: Issue #35 でユーザーページと username が実装済み

**実装内容**:
- ユーザーが他のユーザーをフォローできる
- フォロー/アンフォローボタン（Turbo Streams で非同期更新）
- フォロー数・フォロワー数の表示
- フォロー・フォロワーリスト（`/users/:username/following`, `/users/:username/followers`）
- フォロー通知（右上の通知アイコンで表示）

## 設計上の決定事項

### 1. 自己参照関連（Self-Referential Association）

`follows` テーブルで `follower_id` と `followed_id` を管理し、`has_many :through` で User 間の多対多の関係を表現。

### 2. プライバシー設定

フォローは自動承認（承認制は将来の Issue として切り出す）

### 3. Turbo Streams での非同期更新

フォロー/アンフォローボタンとカウントを自分の画面のみ非同期更新（他のユーザーの画面は更新しない）

### 4. Notification モデルの Polymorphic 拡張

既存の Notification モデルを Polymorphic に変換し、記事公開通知とフォロー通知を統一管理。`post_id` → `notifiable_id` + `notifiable_type` に変換。

## 実装手順

### Phase 1: Follow モデルとマイグレーション実装

**目的**: 自己参照関連のモデルを作成（TDD: Red → Green）

**変更内容**:
1. マイグレーション生成・編集（`follower:references`, `followed:references`）
   - NOT NULL 制約、ユニーク複合インデックス、外部キー（cascade delete）
2. マイグレーション実行: `bin/rails db:migrate`
3. `test/models/follow_test.rb` にテスト追加（一意性、自己フォロー禁止）
4. Follow モデルにバリデーション追加
5. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add Follow model with self-referential associations`

### Phase 2: User モデルに関連付けを追加

**目的**: User モデルにフォロー関連の関連付けとメソッドを実装（TDD: Red → Green）

**変更内容**:
1. `test/models/user_test.rb` にテスト追加（`following`, `followers`, `follow`, `unfollow`, `following?`）
2. User モデルに関連付け追加（`active_follows`, `passive_follows`, `following`, `followers`）
3. User モデルにヘルパーメソッド追加（`follow`, `unfollow`, `following?`）
4. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add follow/unfollow associations and methods to User model`

### Phase 3: Notification モデルを Polymorphic に変換

**目的**: 既存の Notification モデルを Polymorphic に変換（TDD: Red → Green）

**変更内容**:
1. マイグレーション生成・編集（`notifiable_type`, `notifiable_id` 追加、既存データ変換、`post_id` 削除）
2. マイグレーション実行: `bin/rails db:migrate`
3. `test/models/notification_test.rb` を更新（`post` → `notifiable`）
4. Notification モデルを更新（`belongs_to :notifiable, polymorphic: true`）
5. Post モデルを更新（`has_many :notifications, as: :notifiable`）
6. NotifyPublicationJob とビューを更新
7. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `refactor: Convert Notification model to polymorphic association`

### Phase 4: FollowsController とルーティングの追加（フォロー通知を含む）

**目的**: フォロー/アンフォロー機能とフォロー通知の実装（TDD: Red → Green）

**変更内容**:
1. `bin/rails generate controller Follows --no-helper --no-assets`
2. `test/routing/follows_routing_test.rb` と `test/controllers/follows_controller_test.rb` にテスト追加
3. `config/routes.rb` にルート追加（`POST /users/:username/follow`, `DELETE /users/:username/follow`）
4. Follow モデルにコールバック追加（`after_create_commit :create_notification`）
5. FollowsController を実装（認証必須、Turbo Stream で非同期更新）
6. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add FollowsController with follow notifications`

### Phase 5: フォロー/アンフォローボタンのビュー実装

**目的**: Turbo Streams で非同期更新されるボタンを実装

**変更内容**:
1. `app/views/follows/_button.html.erb` を作成（フォロー/アンフォローボタン）
2. `app/views/follows/{create,destroy}.turbo_stream.erb` を作成
3. `app/views/users/show.html.erb` にボタンを追加
4. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add follow/unfollow button with Turbo Streams`

### Phase 6: フォロー数・フォロワー数の表示

**目的**: ユーザーページにフォロー数とフォロワー数を表示

**変更内容**:
1. `app/views/follows/_stats.html.erb` パーシャルを作成
2. `app/views/users/show.html.erb` にフォロー数・フォロワー数を追加
3. Turbo Stream ビューを更新（stats パーシャルを更新）
4. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add following/followers count display`

### Phase 7: UsersController の following/followers アクション追加

**目的**: フォロー・フォロワーリストページの実装（TDD: Red → Green）

**変更内容**:
1. `test/routing/users_routing_test.rb` と `test/controllers/users_controller_test.rb` にテスト追加
2. `config/routes.rb` にルート追加（`/users/:username/following`, `/users/:username/followers`）
3. UsersController に following/followers アクションを実装
4. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add following and followers actions to UsersController`

### Phase 8: フォロー・フォロワーリストのビュー実装

**目的**: フォロー・フォロワーリストページを表示

**変更内容**:
1. `app/views/users/{following,followers}.html.erb` を作成
2. `app/views/users/_user_list.html.erb` パーシャルを作成
3. `app/views/users/show.html.erb` のカウントをリンクに変更
4. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add following and followers list views`

### Phase 9: 通知ビューの更新

**目的**: フォロー通知を右上の通知アイコンで表示

**変更内容**:
1. `app/views/notifications/_notification.html.erb` を更新（Polymorphic 対応）
2. テスト実行: `bin/rails test`（Green）

**コミットメッセージ**: `feat: Add follow notification display in notification dropdown`

### Phase 10: README.md の更新

**目的**: フォロー機能の説明を追加

**変更内容**:
1. フォロー機能の説明と技術的な詳細を追加

**コミットメッセージ**: `docs: Add follow feature documentation to README`

## テスト戦略

- **モデル**: Follow（バリデーション、コールバック）、User（関連付け、ヘルパーメソッド）、Notification（Polymorphic）
- **ルーティング**: FollowsController、UsersController
- **コントローラー**: FollowsController（認証、通知作成）、UsersController（following/followers）

## セキュリティ考慮事項

- 認証と認可: フォロー/アンフォローは認証済みユーザーのみ、自分自身のフォロー禁止
- CSRF 対策: Rails 標準機能で対応
- N+1 クエリ対策: `includes` で関連レコードを事前読み込み

## パフォーマンス最適化

- インデックス: `[follower_id, followed_id]`（ユニーク）、個別インデックス
- N+1 クエリ対策: `includes`
- カウンターキャッシュ: 現時点では不要、将来検討

## 受け入れ基準

- [ ] Follow モデルと User モデルの関連付けが実装されていること
- [ ] Notification モデルが Polymorphic に変換されていること
- [ ] フォロー/アンフォローボタンが機能し、非同期更新されること
- [ ] フォロー数・フォロワー数が表示されること
- [ ] フォロー・フォロワーリストが表示されること
- [ ] フォロー通知が作成・表示されること
- [ ] 全テストが通ること
- [ ] README に説明が記載されていること

## 注意事項

- 各 Phase は Green で終わる（`bin/rails test` が通ることを確認）
- Phase 内で TDD サイクル（Red → Green）を完結させる
- Phase 3 で既存の Notification モデルを変更するため、慎重にテストを実行
- `annotate` は `db:migrate` 時に自動実行されるため、手動実行は不要
