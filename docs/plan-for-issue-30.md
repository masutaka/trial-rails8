# Issue #30: Solid Queue から Sidekiq に移行する - 実装計画

## 概要

バックグラウンドジョブ処理を Solid Queue から Sidekiq に移行する。Sidekiq は成熟したエコシステム、豊富なプラグイン、運用実績があり、本番環境での信頼性が高い。開発環境のみを対象とし、Redis 7.x と Sidekiq 7.x を使用する。

## 現状分析

### 現在の構成

- **Active Job アダプター**: Solid Queue（config/environments/development.rb:73, config/environments/production.rb:53）
- **ジョブ管理 UI**: Mission Control Jobs（config/routes.rb:37）
- **依存関係**:
  - `solid_queue` gem（Gemfile:28）
  - `mission_control-jobs` gem（Gemfile:68）
- **設定ファイル**:
  - config/queue.yml: Solid Queue のワーカー設定
  - db/queue_schema.rb: Solid Queue 用のデータベーススキーマ
- **既存ジョブ**:
  - app/jobs/test_job.rb
  - app/jobs/publish_post_job.rb
  - app/jobs/notify_publication_job.rb

### 移行が必要な箇所

1. Gemfile の依存関係
2. Active Job アダプターの設定（development/production/test）
3. ルーティング（Mission Control → Sidekiq Web UI）
4. Docker Compose 設定（Redis コンテナの追加）
5. 設定ファイルの削除・追加（Sidekiq 設定、initializer）
6. CI 設定（GitHub Actions で Redis サービスを有効化）
7. Procfile.dev（bin/jobs → bin/sidekiq）
8. README.md の更新

## 実装方針

### 技術スタック

- **Sidekiq 7.x**: 最新の安定版を使用
- **Redis 7.x**: Sidekiq のバックエンドストア
- **Sidekiq Web UI**: ジョブ監視（sidekiq gem に標準搭載）

### なぜこのアプローチか

- **既存ジョブの互換性**: Active Job を使用しているため、ジョブクラスの変更は不要
- **段階的な移行**: 環境ごとに設定を分離しているため、development → production の順で移行可能
- **シンプルな構成**: 開発環境のみのため、Redis の高可用性構成は不要

## 実装手順

### Phase 1: Redis コンテナの追加

**目的**: Docker Compose で Redis を起動し、Sidekiq のバックエンドストアを準備する

**変更内容**:

1. `compose.yml` に Redis サービスを追加:
   ```yaml
   redis:
     image: redis:7-alpine
     ports:
       - "6379:6379"
     volumes:
       - redis_data:/data
     command: redis-server --appendonly yes --maxmemory-policy noeviction
   ```

2. `volumes` セクションに Redis のデータボリュームを追加:
   ```yaml
   volumes:
     mysql_data:
     redis_data:
   ```

**理由**:
- Redis 7-alpine は軽量で起動が高速
- `--appendonly yes` で永続化を有効化（AOF モード）
- `--maxmemory-policy noeviction` でデータの自動削除を防止（Sidekiq 公式推奨）

**コミットメッセージ**: `Add Redis container for Sidekiq backend`

### Phase 2: Sidekiq gem の追加と Solid Queue 関連の削除

**目的**: Gemfile を更新し、Sidekiq の依存関係を追加、Solid Queue 関連を削除

**変更内容**:

1. `Gemfile` の変更:
   - 28行目 `gem "solid_queue"` を削除
   - 68行目 `gem "mission_control-jobs"` を削除
   - 以下を追加（26行目の `gem "solid_cache"` の後に配置）:
     ```ruby
     gem "sidekiq", "~> 7.0"
     ```

2. `bundle install` を実行してロックファイルを更新

**理由**:
- Sidekiq 7.x は Redis 5.0+ をサポート
- `mission_control-jobs` は Solid Queue 専用のため不要
- Sidekiq Web UI は sidekiq gem に標準搭載されている

**コミットメッセージ**: `Replace solid_queue with sidekiq gem`

### Phase 3: Sidekiq 設定ファイルの作成

**目的**: Sidekiq の動作設定とキュー設定を定義

**変更内容**:

1. `config/sidekiq.yml` を新規作成:
   ```yaml
   ---
   :concurrency: <%= ENV.fetch("RAILS_MAX_THREADS", 3) %>
   :queues:
     - default
   ```

**理由**:
- `RAILS_MAX_THREADS` を使用することで、データベース接続プール数と整合性を保つ
- Solid Queue は全キュー（`*`）を処理していたが、Sidekiq では明示的に `default` キューを指定
- 既存ジョブはすべてデフォルトキューを使用しているため、これで十分

**コミットメッセージ**: `Add Sidekiq configuration file`

### Phase 4: Sidekiq 初期化ファイルの作成

**目的**: Redis 接続設定とログレベルの設定

**変更内容**:

1. `config/initializers/sidekiq.rb` を新規作成:
   ```ruby
   Sidekiq.configure_server do |config|
     config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
   end

   Sidekiq.configure_client do |config|
     config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
   end
   ```

**理由**:
- 環境変数 `REDIS_URL` で接続先を切り替え可能にする
- デフォルト値で開発環境の Docker Compose Redis に接続
- server/client 両方の設定が必要（server はワーカープロセス、client は Rails アプリケーション）
- Active Job アダプターの設定より先に作成することで、Rails 起動時のエラーを防ぐ

**コミットメッセージ**: `Add Sidekiq initializer for Redis configuration`

### Phase 5: Active Job アダプターの変更

**目的**: Active Job のバックエンドを Solid Queue から Sidekiq に変更

**変更内容**:

1. `config/environments/development.rb`: Solid Queue の設定（`queue_adapter` と `connects_to`）を削除し、`config.active_job.queue_adapter = :sidekiq` に変更
2. `config/environments/production.rb`: 同上
3. `config/environments/test.rb`: `config.active_job.queue_adapter = :inline` を追加

**理由**:
- Sidekiq は Redis を使用するため、データベース接続設定（`connects_to`）は不要
- test 環境では `:inline` アダプターを使用し、ジョブを同期実行（高速化、Redis 不要）

**コミットメッセージ**: `Switch Active Job adapter from Solid Queue to Sidekiq`

### Phase 6: ルーティングの更新

**目的**: Mission Control Jobs を削除し、Sidekiq Web UI を追加

**変更内容**:

1. `config/routes.rb`:
   - ファイル先頭に `require "sidekiq/web"` を追加
   - Mission Control のマウント設定を削除し、`mount Sidekiq::Web => "/sidekiq" if Rails.env.development?` に置き換え

**理由**:
- Sidekiq Web UI は `/sidekiq` パスにマウント（Sidekiq コミュニティの慣例）
- 開発環境のみで有効化（本番環境では認証が必要）

**コミットメッセージ**: `Replace Mission Control Jobs with Sidekiq Web UI`

### Phase 7: CI 設定で Redis サービスを有効化

**目的**: GitHub Actions の CI 環境で Redis を利用可能にする

**変更内容**:

1. `.github/workflows/ci.yml` の変更:
   - 67-71行目のコメントアウトを解除:
     ```yaml
     redis:
       image: redis
       ports:
         - 6379:6379
       options: --health-cmd "redis-cli ping" --health-interval 10s --health-timeout 5s --health-retries 5
     ```
   - 88行目のコメントアウトを解除:
     ```yaml
     REDIS_URL: redis://localhost:6379/0
     ```

**理由**:
- development/production 環境では Sidekiq が Redis を使用するため、統合テストやシステムテストで Redis が必要になる可能性がある
- ヘルスチェックにより、Redis が起動してからテストが実行される
- test 環境では `:inline` アダプターを使用するため実際には Redis に接続しないが、環境変数を設定しておくことで将来的な拡張に対応

**コミットメッセージ**: `Enable Redis service in CI for Sidekiq`

### Phase 8: Procfile.dev の更新

**目的**: `bin/dev` コマンドで Sidekiq を起動できるようにする

**変更内容**:

1. `Procfile.dev` の変更:
   - 3行目を変更:
     ```diff
     - jobs: bin/jobs
     + jobs: bin/sidekiq
     ```

**理由**:
- `bin/jobs` は Solid Queue のワーカー起動コマンド
- `bin/sidekiq` で Sidekiq のワーカープロセスを起動
- `bin/dev` コマンドで Rails サーバー、Tailwind CSS、Sidekiq を一括起動できる

**コミットメッセージ**: `Update Procfile.dev to use Sidekiq instead of Solid Queue`

### Phase 9: development 環境設定から Mission Control 設定を削除

**目的**: 不要になった Mission Control Jobs の設定を削除

**変更内容**:

1. `config/environments/development.rb` の変更:
   - 76-77行目を削除:
     ```ruby
     # Disable Mission Control Jobs authentication in development
     config.mission_control.jobs.http_basic_auth_enabled = false
     ```

**理由**:
- Mission Control Jobs を削除したため、関連設定も不要

**コミットメッセージ**: `Remove Mission Control Jobs configuration`

### Phase 10: Solid Queue 設定ファイルの削除

**目的**: Solid Queue 関連の設定ファイルを削除

**変更内容**:

1. 以下のファイルを削除:
   - `config/queue.yml`

**注意**:
- `db/queue_schema.rb` は削除しない（マイグレーション履歴として保持）
- データベーステーブルは残しておく（必要に応じて後で手動削除可能）

**理由**:
- Sidekiq は Redis を使用するため、queue.yml は不要
- スキーマファイルは履歴として残す（問題が発生した場合のロールバック用）

**コミットメッセージ**: `Remove Solid Queue configuration file`

### Phase 11: README.md の更新

**目的**: セットアップ手順とジョブ監視の説明を Sidekiq 用に更新

**変更内容**:

以下のセクションを Solid Queue から Sidekiq に更新:

1. **### ブログ機能**: `Active Job + Solid Queue` → `Active Job + Sidekiq`（設定ファイルのリンクも更新）
2. **### その他の Rails 8 機能**: `Mission Control Jobs` → `Sidekiq Web UI`（URL を `/sidekiq` に変更）
3. **## セットアップ**: MySQL のみ → MySQL と Redis コンテナを起動
4. **### MySQL コンテナの管理**: タイトルと説明を「MySQL と Redis」に変更
5. **## Active Job の監視**: Mission Control の機能説明 → Sidekiq Web UI の機能説明（リトライ・スケジュール・Redis 統計など）
6. **## データベース構造**: `### Solid Queue（Active Job）` サブセクションを削除
7. **## 参考資料**: `### Background Jobs` セクションを追加（Sidekiq と Sidekiq Wiki）、Solid Trifecta から Solid Queue を削除
8. **### その他のツール**: Mission Control Jobs の項目を削除

**理由**:
- セットアップ手順に Redis の起動を明記
- ジョブ監視 UI のパスと機能を Sidekiq Web UI 用に更新
- 不要になった Solid Queue の ERD と Mission Control Jobs の記述を削除

**コミットメッセージ**: `Update README for Sidekiq migration`

### Phase 12: 動作確認とテスト

**目的**: Sidekiq が正常に動作することを確認

**確認内容**:

1. Redis コンテナの起動確認:
   ```bash
   docker compose up -d
   docker compose ps
   ```

2. Rails サーバーと Sidekiq の起動:
   ```bash
   bin/dev
   ```

3. Sidekiq Web UI へのアクセス:
   - http://localhost:3000/sidekiq にアクセス
   - ダッシュボードが表示されることを確認

4. 既存ジョブの実行テスト:
   ```bash
   bin/rails console
   > TestJob.perform_later
   > PublishPostJob.perform_later(Post.first, Time.current)
   ```
   - Sidekiq のログでジョブが処理されることを確認
   - Web UI でジョブの実行履歴を確認

5. 既存テストの実行:
   ```bash
   bin/rails test
   ```
   - すべてのテストが通ることを確認

**注意**: この Phase はコミットを作成しない（確認作業のみ）

## 考慮事項

### パフォーマンス

- **並行処理数**: `RAILS_MAX_THREADS` 環境変数で調整可能（デフォルト: 3）
- **Redis メモリ**: 開発環境では制限なし、本番環境では `maxmemory` の設定を検討

### エラーハンドリング

- **自動リトライ**: Sidekiq はデフォルトで 25 回リトライ（指数バックオフ）
- **デッドレター**: 25 回失敗後は Dead Jobs に移動し、Web UI から手動リトライ可能

### セキュリティ

- **Web UI の認証**: 本番環境では HTTP Basic 認証または Devise などの認証を追加する必要がある
- **Redis のパスワード**: 本番環境では Redis に認証を設定し、`REDIS_URL` に含める

### 互換性

- **既存ジョブ**: Active Job を使用しているため、ジョブクラスの変更は不要
- **Rails 8**: Sidekiq 7.x は Rails 7.0+ をサポート

## 参考資料

- [Sidekiq 公式ドキュメント](https://github.com/sidekiq/sidekiq)
- [Sidekiq Wiki - Getting Started](https://github.com/sidekiq/sidekiq/wiki/Getting-Started)
- [Sidekiq Wiki - Using Redis](https://github.com/sidekiq/sidekiq/wiki/Using-Redis)
- [Sidekiq Wiki - Monitoring](https://github.com/sidekiq/sidekiq/wiki/Monitoring)
- [Active Job の基礎](https://railsguides.jp/active_job_basics.html)

## 受け入れ基準

- [ ] `docker compose up -d` で MySQL と Redis コンテナが起動すること
- [ ] `bin/sidekiq` で Sidekiq プロセスが正常に起動すること
- [ ] 既存のジョブ（TestJob, PublishPostJob, NotifyPublicationJob）が Sidekiq 経由で実行できること
- [ ] Sidekiq Web UI（http://localhost:3000/sidekiq）でジョブの状態を確認できること
- [ ] 既存のテストが全て通ること
- [ ] README.md の手順に従って、新規開発者が環境構築できること
- [ ] Solid Queue 関連の gem と設定ファイルが削除されていること

## 注意事項

- 各 Phase 後にテストを実行し、既存機能が壊れていないことを確認すること
- Phase 12 で動作確認を必ず実施すること
- 開発時は `bin/dev` コマンドで Rails サーバー、Tailwind CSS、Sidekiq を一括起動できる
- マイグレーションのロールバックは行わない（Solid Queue のテーブルは保持）
