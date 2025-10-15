# Issue #6: 記事の予約投稿機能を実装する

## 概要

- **IssueURL**: https://github.com/masutaka/trial-rails8/issues/6
- **タイトル**: 記事の予約投稿機能を実装する
- **ラベル**: enhancement
- **担当者**: @masutaka

## 目的

記事（Post）に予約投稿機能を追加し、指定した未来の時刻に自動的に公開されるようにします。

## 現状分析

### 既存のモデル

- **Post モデル** (`app/models/post.rb`)
  - `user_id`: 記事の作成者（外部キー）
  - `title`: タイトル
  - `body`: 本文
  - `published_at`: 公開日時（既存）
  - `slug`: URL用のスラッグ
  - `created_at`: 作成日時
  - `updated_at`: 更新日時
  - 関連: `belongs_to :user`, `has_many :comments, dependent: :destroy`

### ActiveJob設定

- **Development & Production**: Solid Queue（Rails 8の新機能）
  - データベース: `:queue` データベースに接続
- **Test**: デフォルト（`:test` または `:async`）

## 実装する機能

### 1. データベース設計

#### Post テーブルへのカラム追加

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| published | boolean | NO | false | 公開済みフラグ |

#### インデックス

- `published_at` にインデックス（予約投稿の検索パフォーマンス向上）
- `published` にインデックス（公開済み記事の絞り込み用）
- 複合インデックス `[published, published_at]`（公開記事の日付順表示に最適化）

### 2. Post モデルの拡張

#### スコープ

- `published`: 公開済み記事（`published: true`）
- `scheduled`: 予約投稿（未公開で`published_at`が未来）
- `draft`: 下書き（未公開で`published_at`が`nil`）
- `ready_to_publish`: 公開可能（未公開で`published_at`が過去または現在）
- `visible_to(user)`: ユーザーに表示可能な記事（ビジネスロジックをモデル層に集約）
  - `user`が存在する場合: 公開記事 + 自分の未公開記事
  - `user`が`nil`の場合: 公開記事のみ

#### メソッド

- `scheduled?`: 予約投稿かどうかを判定
- `draft?`: 下書きかどうかを判定
- `viewable_by?(user)`: 指定されたユーザーが記事を閲覧可能かを判定
  - 公開記事: 誰でも閲覧可能
  - 未公開記事: 作成者のみ閲覧可能
- `previous_post(current_user)` / `next_post(current_user)`: 前後の記事を取得
  - **自分の記事を閲覧中**（`user == current_user`）: 自分の記事（公開・未公開含む）を対象
  - **他人の記事または未認証**: 公開記事のみを対象

#### コールバック

**公開ジョブのスケジュール**
- `after_commit :schedule_publication, on: [:create, :update], if: :should_schedule_publication?`
- ジョブに`published_at`のタイムスタンプ（`published_at.to_i`）を引数として渡す
  - ジョブ実行時に、スケジュール時の`published_at`と現在の`published_at`を比較
  - 異なる場合はスキップ（ユーザーが公開日時を変更した）
  - これにより公開日時の変更（延期・前倒し）が正しく動作
- `published_at`が過去/現在なら即座に実行、未来なら遅延実行
- トランザクションコミット後にジョブをエンキュー

### 3. Active Job の設計

#### PublishPostJob

- `queue_as :default`
- 引数: `post_id`, `scheduled_at`（スケジュール時の`published_at`のタイムスタンプ）
- **実行時チェック**:
  - スケジュール時の`scheduled_at`と現在の`post.published_at.to_i`を比較
  - 異なる場合はスキップ（公開日時が変更された）
  - 既に公開済み（`published: true`）の場合はスキップ（冪等性）
  - `published_at`が未来の場合はスキップ
- 記事を公開（`published: true`に更新）

### 4. PostsController の更新

#### indexアクション

- **認証済みユーザー**: 公開記事 + 自分の未公開記事
- **未認証ユーザー**: 公開記事のみ

#### showアクション

- **アクセス制御**: `viewable_by?(user)` メソッドを使用
  - 公開記事: 誰でも閲覧可能
  - 未公開記事: 作成者のみ閲覧可能、それ以外は404（`raise ActiveRecord::RecordNotFound`）
- `previous_post` / `next_post`の取得
  - `Current.user`を引数として渡す
  - 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）から前後を取得
  - それ以外: 公開記事のみから前後を取得

#### edit/update/destroyアクション

- 既存の`before_action :authorize_author, only: [:edit, :update, :destroy]`を継続使用
- 作成者以外がアクセスした場合は404を返す
- 公開記事・未公開記事ともに同じ権限チェック

#### Strong Parameters の更新

- `post_params`: `:title, :body, :published_at, :slug`
- `published`は自動更新されるため含めない

#### createアクション

- 公開ジョブのスケジュールはモデルのコールバックで自動処理

### 5. ビューの更新

#### 記事フォーム

- `published_at`フィールドを追加（`datetime_field`）
- ヘルプテキスト: 「未来の日時を設定すると、その時刻に自動公開されます。」

#### 記事一覧

- 未公開記事に「Draft」バッジを表示
- 公開済み: 公開日時を表示
- 未公開: 公開予定日時または「公開日時未設定」を表示

#### 記事詳細

- 未公開記事: 警告バナー（Draft / 公開予定日時）を表示
- 公開済み記事: 公開日時を表示

## TDD アプローチに基づく実装手順

t-wada氏の推奨するTDDアプローチに従い、「テストを書く → 実装する → リファクタリング」のサイクルを繰り返します。

### Phase 1: マイグレーション

1. **マイグレーションファイルの作成**
   ```bash
   bin/rails generate migration AddPublishedToPosts published:boolean
   ```

2. **マイグレーションファイルの編集**
   - `published` カラムに `default: false, null: false` を追加
   - インデックスの追加

3. **マイグレーション実行**
   ```bash
   bin/rails db:migrate
   bin/rails db:migrate RAILS_ENV=test
   ```

### Phase 2: モデル（TDD）- 各メソッドを1つずつ実装

1. **`published` スコープ（TDD）**
   - `test/models/post_test.rb` に `published` スコープのテストを追加
   - `published` スコープを実装
   - テストが通ることを確認

2. **`scheduled` スコープ（TDD）**
   - `test/models/post_test.rb` に `scheduled` スコープのテストを追加
   - `scheduled` スコープを実装
   - テストが通ることを確認

3. **`draft` スコープ（TDD）**
   - `test/models/post_test.rb` に `draft` スコープのテストを追加
   - `draft` スコープを実装
   - テストが通ることを確認

4. **`ready_to_publish` スコープ（TDD）**
   - `test/models/post_test.rb` に `ready_to_publish` スコープのテストを追加
   - `ready_to_publish` スコープを実装
   - テストが通ることを確認

5. **`visible_to(user)` スコープ（TDD）**
   - `test/models/post_test.rb` に `visible_to` スコープのテストを追加
     - ユーザーが存在する場合: 公開記事 + 自分の未公開記事が返される
     - ユーザーが`nil`の場合: 公開記事のみが返される
     - 他人の未公開記事は含まれない
   - `visible_to` スコープを実装
   - テストが通ることを確認

6. **`scheduled?` メソッド（TDD）**
   - `test/models/post_test.rb` に `scheduled?` メソッドのテストを追加
   - `scheduled?` メソッドを実装
   - テストが通ることを確認

7. **`draft?` メソッド（TDD）**
   - `test/models/post_test.rb` に `draft?` メソッドのテストを追加
   - `draft?` メソッドを実装
   - テストが通ることを確認

8. **`viewable_by?(user)` メソッド（TDD）**
   - `test/models/post_test.rb` に `viewable_by?` メソッドのテストを追加
     - 公開記事: 誰でも閲覧可能（userが`nil`でも`true`）
     - 未公開記事: 作成者のみ閲覧可能（作成者なら`true`、それ以外は`false`）
   - `viewable_by?` メソッドを実装
   - テストが通ることを確認

9. **`previous_post` / `next_post` メソッド（TDD）**
   - `test/models/post_test.rb` に `previous_post` / `next_post` のテストを追加
     - 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）から前後を取得
     - それ以外: 公開記事のみから前後を取得
   - `previous_post` / `next_post` メソッドを実装
     - `current_user`引数を受け取る
     - 作成者判定ロジック
   - テストが通ることを確認

10. **公開ジョブスケジュールコールバック（TDD）**
   - `test/models/post_test.rb` に公開ジョブスケジュールのテストを追加
     - 保存時にジョブがエンキューされること
     - `published_at` が未来の場合は遅延実行されること
     - `published_at` が過去の場合は即座に実行されること
     - **ジョブに`scheduled_at`引数が渡されること**
   - `after_commit :schedule_publication` コールバックを実装
     - `scheduled_at`引数を渡す
   - テストが通ることを確認

### Phase 3: Job（TDD）

1. **PublishPostJob のテスト作成**
   ```bash
   bin/rails generate job PublishPost
   ```
   - `test/jobs/publish_post_job_test.rb` にテストを記述
   - 正常系：公開フラグがtrueになること
   - 異常系：既に公開済みの場合はスキップ
   - 異常系：published_atが未来の場合はスキップ
   - **異常系：`scheduled_at`と現在の`published_at`が異なる場合はスキップ**

2. **PublishPostJob の実装**
   - ジョブロジックの実装
   - **`scheduled_at`チェックロジックの実装**
   - テストが通ることを確認

### Phase 4: コントローラー（TDD）- 各アクションを1つずつ実装

1. **indexアクション（TDD）**
   - `test/controllers/posts_controller_test.rb` に indexアクションのテストを追加
     - `test "should get index"`: HTTPレスポンスが成功すること
   - `index` アクションを実装
     - 認証状態による表示切り替えは `Post.visible_to(Current.user)` スコープを使用
     - ビジネスロジックをモデル層に委譲し、コントローラーは薄く保つ
   - テストが通ることを確認

2. **showアクション（TDD）**
   - `test/controllers/posts_controller_test.rb` に showアクションのテストを追加
     - 作成者は未公開記事を閲覧できること
     - 他のユーザーは未公開記事にアクセスすると404が返されること
     - 未認証ユーザーは未公開記事にアクセスすると404が返されること
     - 公開記事は誰でも閲覧できること
   - `show` アクションを実装
     - アクセス制御: `@post.viewable_by?(Current.user)` を使用
     - 閲覧不可の場合は `raise ActiveRecord::RecordNotFound`
     - `previous_post` / `next_post` に `Current.user` を渡す
     - ビジネスロジックをモデル層に委譲し、コントローラーは薄く保つ
   - テストが通ることを確認

3. **createアクション（TDD）**
   - `test/controllers/posts_controller_test.rb` に createアクションのテストを追加
     - createアクションが正常に動作すること
   - `create` アクションを実装（必要に応じて）
   - テストが通ることを確認

4. **edit/update/destroyアクション（TDD）**
   - `test/controllers/posts_controller_test.rb` に edit/update/destroyアクションのテストを追加
     - 作成者は編集・削除できること
     - 他のユーザーは404が返されること
     - 未公開記事でも作成者は編集できること
   - edit/update/destroy は既存の`authorize_author`で権限チェック済み（必要に応じて確認）
   - テストが通ることを確認

### Phase 5: ビュー

1. **ビューの更新**
   - フォームに `published_at` フィールドを追加
   - **記事一覧に未公開記事の表示を追加**
     - 未公開記事に「Draft」バッジを表示
     - 公開予定日時または公開日時未設定を表示
   - **記事詳細に未公開記事の状態表示を追加**
     - Draft（下書き）表示
     - 予約投稿の場合は公開予定日時を表示
     - 公開済み記事は公開日時を表示

2. **システムテストの追加**
   - `test/system/posts_test.rb` にテストを追加
   - 予約投稿の作成シナリオ
   - 公開記事のみ表示されることの確認

### Phase 6: 統合テスト

1. **統合テストの作成**
   - `test/integration/scheduled_post_publication_test.rb` を作成
   - 予約投稿から公開までの一連の流れをテスト
   - ジョブの実行を統合的にテスト

## テスト戦略

TDDアプローチに従い、以下の順序でテストを記述します：

### 1. モデルテスト

- スコープのテスト（`published`, `scheduled`, `draft`, `ready_to_publish`, `visible_to`）
- メソッドのテスト（`scheduled?`, `draft?`, `viewable_by?`）
- previous_post / next_post のテスト（作成者判定による振る舞いの違い）
- 公開ジョブスケジュールコールバックのテスト
  - ジョブのエンキュー確認
  - `scheduled_at`引数が正しく渡されることの確認

### 2. Jobテスト

- PublishPostJob: 記事公開、冪等性、`scheduled_at`チェック

### 3. コントローラーテスト

- indexアクション: レスポンスが成功すること
- showアクション: アクセス制御（404が返されること）
  - ビジネスロジック（閲覧可否の判定）は `viewable_by?` のモデルテストで担保
- createアクション: 正常系
- edit/update/destroyアクション:
  - 作成者は編集・削除できること
  - 他のユーザーは404が返されること
  - 未公開記事でも作成者は編集できること

### 4. 統合テスト

- 予約投稿から公開までの一連の流れ
- ジョブ実行の統合テスト

## セキュリティ考慮事項

### 1. 認証と認可

- 予約投稿の作成・編集・削除: 認証済みユーザーのみ
- 記事の編集・削除: 作成者本人のみ
- 未公開記事の閲覧: 作成者のみ（それ以外は404）

### 2. ジョブの安全性

- PublishPostJob の冪等性確保（既に公開済みならスキップ）
- 記事が見つからない場合のエラーハンドリング
- **公開日時変更の対応**
  - スケジュール時の`published_at`をジョブ引数として保存
  - 実行時に現在の`published_at`と比較し、異なる場合はスキップ
  - ActiveJobの抽象化を維持（どのバックエンドでも動作）

### 3. マスアサインメント対策

- `published`はStrong Parametersに含めない

### 4. タイムゾーン対応

- `published_at`はUTCで保存
- `Time.current`を使用

## パフォーマンス最適化

- データベースインデックス: `published`, `published_at`, `[published, published_at]`
- N+1クエリ対策: `includes(:user, :comments)`

## 実装後の確認事項

- [ ] すべてのテストが通ること
  ```bash
  bin/rails test
  bin/rails test:system
  ```
- [ ] マイグレーションが正しく実行されること
- [ ] 予約投稿が指定時刻に公開されること
- [ ] **記事一覧（`/posts`）の動作確認**
  - [ ] 未認証ユーザーは公開記事のみ表示されること
  - [ ] ログインユーザーは公開記事と自分の未公開記事が表示されること
  - [ ] 他人の未公開記事は表示されないこと
  - [ ] 自分の未公開記事に「Draft」バッジが表示されること
- [ ] **未公開記事のアクセス制御（show）**
  - [ ] 作成者は自分の未公開記事を閲覧できること
  - [ ] 他のユーザーは未公開記事にアクセスすると404が返されること
  - [ ] 未認証ユーザーは未公開記事にアクセスすると404が返されること
  - [ ] 未公開記事詳細ページに「Draft」表示があること
- [ ] **previous_post / next_post の動作確認**
  - [ ] 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）で前後移動できること
  - [ ] それ以外: 公開記事のみで前後移動すること
- [ ] **編集権限の確認**
  - [ ] 作成者は自分の記事（Draft含む）を編集・削除できること
  - [ ] 他のユーザーは編集・削除しようとすると404が返されること
- [ ] ジョブが正しくエンキューされること（Solid Queue の確認）
  ```bash
  bin/rails solid_queue:status
  ```

## 参考資料

- [Active Job Basics - Rails Guides](https://railsguides.jp/active_job_basics.html)
- [Solid Queue - Rails 8 新機能](https://github.com/rails/solid_queue)
- [TDD（テスト駆動開発）- t-wada](https://www.youtube.com/watch?v=Q-FJ3XmFlT8)
- [Rails Testing Guide](https://railsguides.jp/testing.html)
