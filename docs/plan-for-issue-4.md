# Issue #4: 各記事にコメント機能を追加する

## 概要

- **IssueURL**: https://github.com/masutaka/trial-rails8/issues/4
- **タイトル**: 各記事にコメント機能を追加する
- **ラベル**: enhancement
- **担当者**: @masutaka

## 目的

記事（Post）に対してユーザーがコメントを投稿できる機能を追加します。

## 現状分析

### 既存のモデル

- **Post モデル** (`app/models/post.rb`)
  - `user_id`: 記事の作成者
  - `title`: タイトル
  - `body`: 本文
  - `published_at`: 公開日時
  - `slug`: URL用のスラッグ（`to_param` で使用）
  - 関連: `belongs_to :user`

- **User モデル**
  - 認証機能あり（email_address, password_digest）

### 既存のルーティング

```ruby
resources :posts, param: :slug
```

### テストフレームワーク

- Minitest を使用
- `ActionDispatch::IntegrationTest` ベースのテスト

## 実装する機能

### 1. Comment モデル

#### カラム設計

| カラム名 | 型 | NULL | 説明 |
|---------|-----|------|------|
| id | integer | NO | 主キー |
| post_id | integer | NO | 記事ID（外部キー） |
| user_id | integer | NO | コメント投稿者ID（外部キー） |
| body | text | NO | コメント本文 |
| created_at | datetime | NO | 作成日時 |
| updated_at | datetime | NO | 更新日時 |

#### インデックス

- `post_id` にインデックス（検索パフォーマンス向上）
- `user_id` にインデックス（検索パフォーマンス向上）

#### 関連（アソシエーション）

```ruby
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user
end

class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
end

class User < ApplicationRecord
  has_many :posts
  has_many :comments
end
```

#### バリデーション

```ruby
class Comment < ApplicationRecord
  validates :body, presence: true, length: { minimum: 1, maximum: 10000 }
end
```

### 2. ルーティング設計

```ruby
resources :posts, param: :slug do
  resources :comments, shallow: true
end
```

#### shallow オプションについて

`shallow: true` を指定することで、以下のようなルーティングが生成されます：

**親のコンテキストが必要なアクション（index, new, create）**:
- `GET    /posts/:post_slug/comments`          → `comments#index`
- `GET    /posts/:post_slug/comments/new`      → `comments#new`
- `POST   /posts/:post_slug/comments`          → `comments#create`

**親のコンテキストが不要なアクション（show, edit, update, destroy）**:
- `GET    /comments/:id`                       → `comments#show`
- `GET    /comments/:id/edit`                  → `comments#edit`
- `PATCH  /comments/:id`                       → `comments#update`
- `DELETE /comments/:id`                       → `comments#destroy`

これにより、URL が不必要に長くならず、RESTful な設計を保ちながらシンプルなルーティングを実現できます。

### 3. CommentsController の設計

#### アクション

- `index`: 記事のコメント一覧（オプション、ビューで表示する場合は不要かも）
- `new`: コメント作成フォーム（または記事詳細ページに埋め込み）
- `create`: コメントの作成
- `edit`: コメント編集フォーム
- `update`: コメントの更新
- `destroy`: コメントの削除

#### 認証・認可

- コメントの作成: ログインユーザーのみ
- コメントの編集・削除: コメント作成者本人のみ

#### Strong Parameters

```ruby
def comment_params
  params.require(:comment).permit(:body)
end
```

### 4. ビューの設計

#### 必要なビュー

1. **記事詳細ページ** (`app/views/posts/show.html.erb`)
   - コメント一覧の表示
   - 新規コメント投稿フォーム（ログインユーザーのみ）

2. **コメント編集フォーム** (`app/views/comments/edit.html.erb`)
   - コメント本文の編集フォーム

#### パーシャル

- `app/views/comments/_comment.html.erb`: 個別コメントの表示
- `app/views/comments/_form.html.erb`: コメントフォーム（新規・編集共通）

## TDD アプローチに基づく実装手順

Issue #4 では「ルーティングのテストを書いてから、ルーティングを追加してほしい」と指定されているため、以下の順序で実装します。

### Phase 1: ルーティング（TDD）

1. **ルーティングテストファイルの作成**
   - `test/routing/comments_routing_test.rb` を作成
   - shallow ルーティングのテストを記述

2. **ルーティングの追加**
   - `config/routes.rb` に `resources :comments, shallow: true` を追加
   - テストが通ることを確認

### Phase 2: モデル（TDD）

3. **Comment モデルのマイグレーション作成**
   ```bash
   bin/rails generate model Comment post:references{null:false} user:references{null:false} body:text{null:false}
   ```

4. **モデルテストの作成**
   - `test/models/comment_test.rb` にテストを記述
   - バリデーションのテスト
   - 関連のテスト

5. **Comment モデルの実装**
   - バリデーションの追加
   - アソシエーションの確認
   - テストが通ることを確認

6. **Post モデルの更新**
   - `has_many :comments, dependent: :destroy` の追加
   - 関連テストの追加（記事削除時にコメントも削除されることを確認）

### Phase 3: コントローラー（TDD）

7. **CommentsController のテスト作成**
   - `test/controllers/comments_controller_test.rb` を作成
   - 各アクションのテストを記述
   - 認証・認可のテスト

8. **CommentsController の実装**
   ```bash
   bin/rails generate controller Comments
   ```
   - 各アクションの実装
   - `before_action` による認証・認可チェック
   - テストが通ることを確認

### Phase 4: ビュー

9. **ビューの作成**
   - `app/views/comments/_comment.html.erb`
   - `app/views/comments/_form.html.erb`
   - `app/views/comments/edit.html.erb`
   - `app/views/posts/show.html.erb` の更新（コメント表示部分を追加）

10. **システムテストの追加**
    - `test/system/comments_test.rb` を作成
    - コメント投稿のシナリオテスト
    - コメント編集・削除のシナリオテスト

## テスト戦略

### 1. ルーティングテスト

```ruby
# test/routing/comments_routing_test.rb
require "test_helper"

class CommentsRoutingTest < ActionDispatch::IntegrationTest
  test "routes to comments#create nested under posts" do
    assert_routing(
      { method: "post", path: "/posts/my-post-slug/comments" },
      { controller: "comments", action: "create", post_slug: "my-post-slug" }
    )
  end

  test "routes to comments#edit with shallow route" do
    assert_routing(
      { method: "get", path: "/comments/1/edit" },
      { controller: "comments", action: "edit", id: "1" }
    )
  end

  # その他のルーティングテスト...
end
```

### 2. モデルテスト

- バリデーションのテスト（presence, length）
- アソシエーションのテスト
- 外部キー制約のテスト

### 3. コントローラーテスト

- 各アクションのレスポンステスト
- 認証が必要なアクションへの未ログインアクセステスト
- 他人のコメント編集・削除の拒否テスト
- Strong Parameters のテスト

### 4. システムテスト

- ユーザーがコメントを投稿する一連の流れ
- コメントの編集・削除の流れ
- 未ログインユーザーにはコメントフォームが表示されないこと

## セキュリティ考慮事項

### 1. 認証（Authentication）

- コメントの作成、編集、削除にはログインが必須
- `before_action :require_authentication` を使用

### 2. 認可（Authorization）

- コメントの編集・削除は作成者本人のみ許可
- コントローラーで `@comment.user == Current.user` をチェック

### 3. XSS 対策

- コメント本文の表示時には Rails のデフォルトのエスケープ処理を使用
- HTMLタグをそのまま表示する場合は `sanitize` ヘルパーを使用

### 4. CSRF 対策

- Rails のデフォルトの CSRF トークン検証を使用
- フォームに `form_with` または `form_for` を使用

### 5. マスアサインメント対策

- Strong Parameters を使用して許可する属性を明示的に指定
- `post_id` と `user_id` はコントローラーで明示的に設定し、ユーザー入力からは受け取らない

### 6. SQL インジェクション対策

- Active Record の機能を使用し、生の SQL を直接書かない

## 実装後の確認事項

- [ ] すべてのテストが通ること
- [ ] ルーティングが期待通りに動作すること（`bin/rails routes | grep comments` で確認）
- [ ] 記事詳細ページでコメントの投稿・表示ができること
- [ ] ログインユーザーのみがコメントを投稿できること
- [ ] コメント作成者のみが自分のコメントを編集・削除できること
- [ ] 未ログインユーザーにはコメントフォームが表示されないこと

## 参考資料

- [Rails Routing from the Outside In - Rails Guides](https://railsguides.jp/routing.html)
- [Action Controller Overview - Rails Guides](https://railsguides.jp/action_controller_overview.html)
- [Active Record Associations - Rails Guides](https://railsguides.jp/association_basics.html)
