# Issue #51: MySQL の接続情報を環境変数で設定可能にする - 実装計画

## 概要

MySQL接続設定を環境変数で設定可能にし、開発環境でのポート番号変更などに柔軟に対応する。

**実装内容**:
- dotenv-rails gem を導入し、`.env` ファイルで環境変数を管理
- docker compose と Rails で同じ `.env` ファイルを使用
- `.env.example` をコピーして `.env` を作成する方式

## 設計上の決定事項

### 環境変数

`.env` ファイルで以下の環境変数を定義:
- `MYSQL_HOST`: MySQL のホスト名
- `MYSQL_PORT`: MySQL のポート番号
- `MYSQL_USERNAME`: MySQL のユーザー名
- `MYSQL_PASSWORD`: MySQL のパスワード

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

1. `compose.yml` の `db` サービスを環境変数対応に変更:
   - `MYSQL_ROOT_PASSWORD`: `${MYSQL_PASSWORD}`
   - `ports`: `"${MYSQL_PORT}:3306"`
2. `docker compose up -d` で MySQL が起動することを確認

**コミットメッセージ**: `feat: Support environment variables in compose.yml`

### Phase 4: database.yml の環境変数対応

1. `config/database.yml` の `default` セクションを更新:
   - `host`: `<%= ENV["MYSQL_HOST"] %>`
   - `port`: `<%= ENV["MYSQL_PORT"] %>`
   - `username`: `<%= ENV["MYSQL_USERNAME"] %>`
   - `password`: `<%= ENV["MYSQL_PASSWORD"] %>`
2. `bin/rails db:migrate:status` で動作確認
3. `bin/rails test` で全テストが通ることを確認

**コミットメッセージ**: `feat: Support environment variables for MySQL connection settings`

### Phase 5: CI の環境変数設定

1. GitHub Actions の設定ファイルに環境変数を追加:
   - `MYSQL_HOST: 127.0.0.1`
   - `MYSQL_PORT: 3306`
   - `MYSQL_USERNAME: root`
   - `MYSQL_PASSWORD: password`
2. CI で `bin/rails test` が通ることを確認

**コミットメッセージ**: `ci: Add MySQL environment variables for CI`

### Phase 6: README.md の更新

1. 環境変数のカスタマイズ方法を追加:
   - `.env.example` を `.env` にコピーして、必要に応じて値を変更
   - 詳細は `.env.example` を参照するよう案内

**コミットメッセージ**: `docs: Add environment variables customization guide to README`

## 受け入れ基準

- [ ] dotenv-rails gem がインストールされていること
- [ ] `.env.example` にMySQL接続情報の環境変数が記載されていること
- [ ] `compose.yml` と `database.yml` で環境変数を使用していること
- [ ] `.env` ファイルを作成すれば動作すること
- [ ] 既存のテストとCIが通ること
- [ ] README.md に `.env` のカスタマイズ方法が追加されていること

## 注意事項

- **各 Phase は Green で終わる**: 全ての Phase で `bin/rails test` が通ることを確認
- **セキュリティ**: `.env` は `.gitignore` で除外済み。本番環境では環境変数で機密情報を管理
