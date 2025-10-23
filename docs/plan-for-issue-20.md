# Issue #20: sqlite3 から MySQL に移行する - 実装計画

## 概要

データベースを sqlite3 から MySQL に移行する。開発環境のみを対象とし、Docker Compose を使って MySQL 8.0 を実行する。Rails 8 の Solid Queue、Solid Cable もすべて MySQL で動作するよう設定する。

## 背景

- 本番環境では通常 sqlite3 よりも MySQL や PostgreSQL が使われる
- 開発環境と本番環境のデータベースを統一することで、環境差異による問題を回避できる
- MySQL 固有の機能や制約を開発時から確認できる

## 実装方針

### 技術スタック

- **MySQL 8.0**: メインデータベース
- **mysql2 gem**: Rails の MySQL アダプタ
- **Docker Compose**: MySQL コンテナの管理

### 現在の設定状況

- **Gemfile**: sqlite3 gem が設定されている
- **config/database.yml**: SQLite 用の設定（development、test、production）
- **マルチデータベース構成**:
  - primary: メインアプリケーション
  - queue: Solid Queue (Active Job)
  - cable: Solid Cable (Action Cable)

## 実装手順

### Phase 1: 依存関係の更新

**目的**: Gemfile を MySQL 用に更新

**変更内容**:

1. `Gemfile` の修正:
   - `gem "sqlite3", ">= 2.1"` の行を削除
   - `gem "mysql2", "~> 0.5"` を追加

2. 依存関係のインストール:
   - `bundle install` を実行

**効果**: Rails が MySQL に接続できるようになる

### Phase 2: Docker 環境の構築

**目的**: MySQL 8.0 コンテナを Docker Compose で起動

**変更内容**:

1. `compose.yml` を新規作成:
   ```yaml
   services:
     db:
       image: mysql:8.0
       environment:
         MYSQL_ROOT_PASSWORD: password
         MYSQL_DATABASE: trial_rails8_development
       ports:
         - "3306:3306"
       volumes:
         - mysql_data:/var/lib/mysql
       command:
         - --character-set-server=utf8mb4
         - --collation-server=utf8mb4_unicode_ci
         - --default-time-zone=+09:00

   volumes:
     mysql_data:
   ```

**効果**: `docker compose up` で MySQL が起動する

### Phase 3: データベース設定の更新

**目的**: Rails が MySQL に接続できるよう database.yml を更新

**変更内容**:

1. `config/database.yml` を MySQL 用に書き換え:
   - adapter: `mysql2` に変更
   - host、port、username、password、database 名を設定
   - development 環境:
     - primary: `trial_rails8_development`
     - queue: `trial_rails8_development_queue`
     - cable: `trial_rails8_development_cable`
   - test 環境:
     - database: `trial_rails8_test`
   - production 環境は変更なし（開発環境のみ考慮）

**設定例**:

```yaml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: 127.0.0.1
  port: 3306

development:
  primary:
    <<: *default
    database: trial_rails8_development
  queue:
    <<: *default
    database: trial_rails8_development_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: trial_rails8_development_cable
    migrations_paths: db/cable_migrate

test:
  <<: *default
  database: trial_rails8_test
```

**効果**: Rails が MySQL の各データベースに接続できる

### Phase 4: ドキュメントの更新

**目的**: 新規開発者が MySQL 環境を構築できるよう README を更新

**変更内容**:

1. `README.md` のセットアップセクションを更新:
   - Docker Compose で MySQL を起動する手順を追加
   - データベースの依存関係に関する説明を追加

**更新内容**:

````markdown
## セットアップ

### 前提条件

- Docker と Docker Compose がインストールされていること

### 手順

1. MySQL コンテナを起動:

```bash
docker compose up -d
```

2. 依存関係のインストール、データベース作成、サーバー起動:

```bash
bin/setup
```

http://localhost:3000 から、アプリケーションにアクセスできます。

### MySQL コンテナの管理

- コンテナの起動: `docker compose up -d`
- コンテナの停止: `docker compose down`
- データの削除（完全リセット）: `docker compose down -v`
````

**効果**: 新規開発者が手順通りに環境構築できる

### Phase 5: 動作確認とテスト

**目的**: MySQL 環境で正常に動作することを確認

**確認項目**:

1. MySQL コンテナの起動:
   ```bash
   docker compose up -d
   ```

2. データベースの作成とマイグレーション:
   ```bash
   bin/rails db:create db:migrate
   ```

3. アプリケーションの起動:
   ```bash
   bin/dev
   ```

4. テストの実行:
   ```bash
   rails test
   ```

**受け入れ基準**:

- ✅ `docker compose up` で MySQL コンテナが起動すること
- ✅ `rails db:create db:migrate` が正常に実行できること
- ✅ アプリケーションが MySQL で正常に起動すること
- ✅ 既存のテストが全て通ること
- ✅ README.md の手順に従って、新規開発者が環境構築できること

**注意事項**:

- sqlite3 のデータは移行不要（開発用のサンプルデータのみのため）
- Phase 5 は検証のみでコミットは不要

## 参考資料

### Rails 公式ドキュメント

- [Configuring a Database - Rails Guides](https://guides.rubyonrails.org/configuring.html#configuring-a-database)
- [Active Record Multiple Databases](https://guides.rubyonrails.org/active_record_multiple_databases.html)
- [Active Job Basics - Solid Queue](https://guides.rubyonrails.org/active_job_basics.html)

### mysql2 gem

- [brianmario/mysql2 - GitHub](https://github.com/brianmario/mysql2)

### Docker

- [MySQL - Docker Hub](https://hub.docker.com/_/mysql)

## 考慮事項

- **文字コード**: utf8mb4 を使用（絵文字対応）
- **タイムゾーン**: Asia/Tokyo（日本時間）に設定
- **データ永続化**: Docker の名前付きボリュームを使用
- **ポート**: 3306 をホストに公開（必要に応じて変更可能）
- **パスワード**: 開発環境なので簡易的な `password` を使用
- **production 環境**: 今回は変更しない（開発環境のみ考慮）

## 注意事項

- 各 Phase は atomic な変更で、1 コミットに対応
- Phase 1-4 を順番に実装し、Phase 5 で動作確認
- 既存のテストが壊れていないことを必ず確認
- storage/ ディレクトリの sqlite3 ファイルは削除不要（.gitignore 済み）
