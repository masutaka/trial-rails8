# Issue #35: ユーザーページの実装 - 実装計画

## 概要

現在のアプリケーションでは、ユーザーを識別する情報が email_address しかない。将来的なフォロー機能（#14）の実装に向けて、ユーザーページと username を実装する。

**実装内容**:
- User モデルに username カラムを追加（URL セーフ、一意性）
- `/users/:username` でアクセス可能なユーザーページ
- ユーザーの公開済み投稿一覧を表示

## 設計上の決定事項

### 1. username の仕様
- **フォーマット**: 小文字英数字、ハイフン、アンダースコア（`/\A[a-z0-9_-]+\z/`）
- **長さ**: 3〜30文字
- **一意性**: 大文字小文字を区別しない
- **変更**: 可能（将来のプロフィール編集機能で対応）

### 2. `/users/:username` ルーティングを採用

**理由**:
- 予約語の管理が不要（ルートの競合リスクなし）
- RESTful で保守しやすい
- 将来の機能追加時も安全

**代替案との比較**:
- `/:username` は予約語リストのメンテナンスが必要
- `/users/:username` なら `posts`, `admin`, `settings` などを自由に追加可能

### 3. users テーブルに username を追加

**理由**:
- username は頻繁にアクセスされる識別子（投稿一覧、コメント表示など）
- profiles テーブル分離は現時点では過剰設計
- bio、avatar など「プロフィールページ専用」の情報が 3つ以上必要になったら、その時に profiles テーブルを検討

### 4. 既存ユーザーへの対応

**方針**: seed.rb で username を設定（マイグレーションでのデータ変更は不要）

## 実装手順

### Phase 1: username カラムの追加とバリデーション実装

**目的**: username カラムを追加し、バリデーションを実装（TDD: Red → Green）

**変更内容**:
1. マイグレーションファイルを生成・編集（`username:string`, NOT NULL, UNIQUE）
2. マイグレーション実行: `bin/rails db:migrate`（annotate が自動実行される）
3. `test/models/user_test.rb` にバリデーションテストを追加（Red）
   - 存在性、一意性、フォーマット、長さの検証
4. User モデルに username バリデーションを追加（Green）
   - 存在性、一意性（大文字小文字を区別しない）、長さ（3〜30文字）、フォーマット
   - `normalizes` で小文字化・空白除去
5. テスト実行: `bin/rails test`（全テストが通ることを確認 = Green）

**コミットメッセージ**: `feat: Add username column and validation to User model`

### Phase 2: seed.rb の更新

**目的**: ユーザー作成時に username を設定

**変更内容**:
1. `db/seeds.rb` で alice と bob に username を追加
2. `bin/rails db:reset` でデータベースを再作成
3. テスト実行: `bin/rails test`（全テストが通ることを確認 = Green）

**コミットメッセージ**: `db: Add username to seed users`

### Phase 3: users コントローラとルーティングの追加

**目的**: ユーザーページの表示機能を実装（TDD: Red → Green）

**変更内容**:
1. `bin/rails generate controller Users show --no-helper --no-assets`
2. `test/routing/users_routing_test.rb` を作成してルーティングテストを追加（Red）
   - `/users/:username` が `users#show` にルーティングされること
3. `test/controllers/users_controller_test.rb` にコントローラテストを追加（Red）
   - ユーザーが存在する場合の正常表示
   - ユーザーが存在しない場合の 404 エラー
   - 公開済み投稿が表示されること
   - 未公開投稿が表示されないこと
4. `config/routes.rb` にルートを追加:
   ```ruby
   resources :users, only: [:show], param: :username
   ```
5. UsersController#show を実装（Green）
   - `find_by!` で username 検索
   - 公開済み投稿を取得
6. テスト実行: `bin/rails test`（全テストが通ることを確認 = Green）

**コミットメッセージ**: `feat: Add UsersController#show with routing`

### Phase 4: ユーザーページビューの作成

**目的**: ユーザー情報と投稿一覧を表示

**変更内容**:
1. `app/views/users/show.html.erb` を作成
   - username を `@username` 形式で表示
   - 既存の投稿パーシャルを再利用して投稿一覧を表示
2. テスト実行: `bin/rails test`（全テストが通ることを確認 = Green）

**コミットメッセージ**: `feat: Add user profile page view`

### Phase 5: 既存ビューへのユーザーページリンク追加

**目的**: 投稿一覧、投稿詳細、コメントからユーザーページへリンク

**変更内容**:
1. `app/views/posts/_post.html.erb` - 投稿者を username リンクに変更
2. `app/views/posts/show.html.erb` - 投稿者を username リンクに変更
3. `app/views/comments/_comment.html.erb` - コメント投稿者を username リンクに変更
   - 表示形式: `@username` （例: `@alice`）
4. テスト実行: `bin/rails test`（全テストが通ることを確認 = Green）

**コミットメッセージ**: `feat: Add user profile links to posts and comments`

### Phase 6: README.md の更新

**目的**: ユーザーページ機能の説明を追加

**変更内容**:
1. ユーザーページ機能の説明（`/users/:username` でアクセス可能）
2. username の仕様（URL セーフ、一意性、変更可能）

**コミットメッセージ**: `docs: Add user profile page documentation to README`

## 考慮事項

- **username の変更**: 現時点では変更 UI は提供しないが、モデル層では変更可能
- **パフォーマンス**: username にユニークインデックス追加済み
- **将来の拡張**: bio、avatar、displayname などは profiles テーブル検討時に対応

## 参考資料

- [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)
- [Rails Routing from the Outside In](https://guides.rubyonrails.org/routing.html)
- [Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)

## 受け入れ基準

- [ ] User モデルに username カラムが追加され、適切なバリデーションが設定されていること
- [ ] seed.rb のユーザー（alice, bob）に username が設定されていること
- [ ] `/users/:username` でユーザーページにアクセスできること
- [ ] ユーザーページに投稿一覧が表示されること
- [ ] 投稿、コメントからユーザーページへのリンクが機能すること
- [ ] 全てのテストが通ること（モデル、コントローラ）
- [ ] README.md にユーザーページ機能の説明が記載されていること

## 注意事項

- **各 Phase は Green で終わる**: 全ての Phase の最後で `bin/rails test` が通ることを確認
- **Phase 内で TDD サイクル**: テストが必要な Phase では、Phase 内で Red → Green サイクルを完結させる
- **annotate**: `db:migrate` 時に自動実行されるため、手動実行は不要
- **将来の拡張**: username の変更 UI、displayname、プロフィール画像などは別 Issue で対応
