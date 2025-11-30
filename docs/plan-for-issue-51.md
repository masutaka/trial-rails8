# Issue #51: MySQL の接続情報を環境変数で設定可能にする - 実装計画

## 概要

MySQL接続設定を環境変数で設定可能にし、開発環境でのポート番号変更などに柔軟に対応する。

**実装内容**:
- dotenv-rails gem を導入し、`.env` ファイルで環境変数を管理
- docker compose と Rails で同じ `.env` ファイルを使用
- デフォルト値を提供し、CI やテストへの影響を回避

## 設計上の決定事項

### 環境変数とデフォルト値

`ENV.fetch` でデフォルト値を提供し、環境変数未設定でも動作する:
- `MYSQL_HOST`: `127.0.0.1`
- `MYSQL_PORT`: `3306`
- `MYSQL_USERNAME`: `root`
- `MYSQL_PASSWORD`: `password`

### dotenv-rails の導入

docker compose と Rails の両方で `.env` ファイルを読み込み、1つのファイルで環境変数を管理。

## 実装手順

### Phase 1: dotenv-rails gem の追加

1. `Gemfile` の `group :development, :test` に `gem "dotenv-rails"` を追加
2. `bundle install` を実行
3. `bin/rails test` で全テストが通ることを確認

**コミットメッセージ**: `feat: Add dotenv-rails gem for environment variable management`

### Phase 2: .env.example の作成

1. `.env.example` を作成:
   ```bash
   # MySQL connection settings (customize as needed)
   MYSQL_HOST=127.0.0.1
   MYSQL_PORT=3306
   MYSQL_USERNAME=root
   MYSQL_PASSWORD=password
   ```

**コミットメッセージ**: `feat: Add .env.example for MySQL connection settings`

### Phase 3: compose.yml の環境変数対応

1. `compose.yml` の `db` サービスの `ports` を `"${MYSQL_PORT:-3306}:3306"` に変更
2. `docker compose up -d` で MySQL が起動することを確認

**コミットメッセージ**: `feat: Support MYSQL_PORT environment variable in compose.yml`

### Phase 4: database.yml の環境変数対応

1. `config/database.yml` の `default` セクションを更新:
   - `host`: `<%= ENV.fetch("MYSQL_HOST", "127.0.0.1") %>`
   - `port`: `<%= ENV.fetch("MYSQL_PORT", "3306") %>`
   - `username`: `<%= ENV.fetch("MYSQL_USERNAME", "root") %>`
   - `password`: `<%= ENV.fetch("MYSQL_PASSWORD", "password") %>`
2. `bin/rails db:migrate:status` で動作確認
3. `bin/rails test` で全テストが通ることを確認

**コミットメッセージ**: `feat: Support environment variables for MySQL connection settings`

### Phase 5: CI の動作確認

1. CI で `bin/rails test` が通ることを確認（デフォルト値で動作）

**注意**: CI の設定変更が不要な場合、コミットを作成しない

### Phase 6: README.md の更新

1. 環境変数のカスタマイズ方法を追加:
   - `.env.example` を `.env` にコピーして、必要に応じて値を変更
   - 詳細は `.env.example` を参照するよう案内

**コミットメッセージ**: `docs: Add environment variables customization guide to README`

## 受け入れ基準

- [ ] dotenv-rails gem がインストールされていること
- [ ] `.env.example` にMySQL接続情報の環境変数が記載されていること
- [ ] `compose.yml` と `database.yml` で環境変数を使用していること
- [ ] 環境変数未設定時、デフォルト値で動作すること
- [ ] 既存のテストとCIが通ること
- [ ] README.md に `.env` のカスタマイズ方法が追加されていること

## 注意事項

- **各 Phase は Green で終わる**: 全ての Phase で `bin/rails test` が通ることを確認
- **セキュリティ**: `.env` は `.gitignore` で除外済み。本番環境では環境変数で機密情報を管理
