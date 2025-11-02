# Issue #42: N+1クエリ問題を検出できる仕組みの導入 - 実装計画

## 概要

Bullet gem を使用してN+1クエリを自動検出する仕組みを導入する。開発環境ではブラウザ通知とログ出力、テスト環境ではエラー発生によりCI/CDでの自動チェックを実現する。

**実装内容**:
- Bullet gem の導入（development と test 環境）
- 開発環境: ブラウザ通知、コンソール出力、ログ出力
- テスト環境: N+1検出時にエラー発生（CI/CD対応）
- Minitest と Active Job との統合

## 設計上の決定事項

### 1. Bullet gem を採用

最も広く使われているN+1検出gem（Trust Score 10/10）。Minitest と Active Job との統合が容易で、豊富な通知方法をサポート。

### 2. 公式ジェネレータの使用を検討

`bundle exec rails g bullet:install` でベストプラクティスに基づいた設定ファイルが生成される。Phase 2 で生成内容を確認し、そのまま使うか手動設定するか判断する。

### 3. テスト環境での動作

`Bullet.raise = true` でN+1クエリ検出時にテストを失敗させ、CI/CDでの自動検出を実現する。

## 実装手順

### Phase 1: Bullet gem の追加

**変更内容**:
1. `Gemfile` の `group :development, :test` に追加: `gem "bullet"`
2. `bundle install` を実行

**コミットメッセージ**: `feat: Add bullet gem for N+1 query detection`

### Phase 2: ジェネレータの実行と判断

**変更内容**:
1. `bundle exec rails g bullet:install` を実行
2. 生成されたファイルと内容を確認
3. **判断**: 生成された設定が適切か確認
   - 適切な場合 → そのまま使用（Phase 3で調整）
   - 不適切な場合 → 生成ファイルを削除し、Phase 3で手動設定

**注意**: 判断結果により Phase 3 の内容が変わる

### Phase 3: Bullet 設定の調整または手動設定

**ケース A: ジェネレータの設定を使用する場合**

生成されたファイルを必要に応じて調整:
- 開発環境: `alert`, `console`, `bullet_logger`, `rails_logger` を有効化
- テスト環境: `raise = true`, `bullet_logger` を有効化

**ケース B: 手動設定する場合**

1. `config/environments/development.rb` に追加:
   ```ruby
   config.after_initialize do
     Bullet.enable = true
     Bullet.alert = true
     Bullet.console = true
     Bullet.bullet_logger = true
     Bullet.rails_logger = true
   end
   ```

2. `config/environments/test.rb` に追加:
   ```ruby
   config.after_initialize do
     Bullet.enable = true
     Bullet.bullet_logger = true
     Bullet.raise = true
   end
   ```

**確認**: `bin/rails test` が通ることを確認

**コミットメッセージ**: `feat: Configure Bullet for development and test environments`

### Phase 4: Minitest との統合

**変更内容**:

`test/test_helper.rb` の `ActiveSupport::TestCase` 内に追加:
```ruby
def before_setup
  Bullet.start_request if defined?(Bullet)
  super
end

def after_teardown
  super
  if defined?(Bullet)
    Bullet.perform_out_of_channel_notifications if Bullet.notification?
    Bullet.end_request
  end
end
```

**確認**: `bin/rails test` が通ることを確認

**コミットメッセージ**: `feat: Integrate Bullet with Minitest`

### Phase 5: Active Job との統合

**変更内容**:

`app/jobs/application_job.rb` に追加:
```ruby
include Bullet::ActiveJob if Rails.env.development?
```

**確認**: `bin/rails test` が通ることを確認

**コミットメッセージ**: `feat: Enable Bullet for Active Job in development`

### Phase 6: 動作確認

**確認内容**:
1. `bin/dev` で開発サーバー起動、各ページを巡回してBullet警告が出ないか確認
2. `bin/rails test` で全テストが通ることを確認
3. `tail -f log/bullet.log` でログ出力を確認

**注意**: この Phase はコミットを作成しない

### Phase 7: README.md の更新

**変更内容**:
1. **## パフォーマンス最適化** セクションを追加し、Bullet の動作を説明
2. **## 参考資料** に Bullet の項目を追加

**コミットメッセージ**: `docs: Add documentation for Bullet N+1 query detection`

## 考慮事項

### パフォーマンスへの影響

開発・テスト環境でのみ動作し、本番環境への影響はなし。

### False Positive の対処

必要に応じて `config/initializers/bullet.rb` で safelist に追加可能:
```ruby
Bullet.add_safelist type: :n_plus_one_query, class_name: "Post", association: :comments
```

### 既存のN+1クエリ

Phase 6 でN+1が発見された場合は別 Issue で修正を計画する。

## 参考資料

- [Bullet - GitHub](https://github.com/flyerhzm/bullet)
- [Rails Guides - Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)

## 受け入れ基準

- [ ] Bullet gem がインストールされていること
- [ ] 開発環境で Bullet が有効化され、適切な通知方法が設定されていること
- [ ] テスト環境で `Bullet.raise = true` が設定されていること
- [ ] Minitest と Bullet が統合されていること
- [ ] ApplicationJob に `Bullet::ActiveJob` が include されていること
- [ ] 既存のテストがすべて通ること
- [ ] README.md に N+1 検出の説明が追加されていること

## 注意事項

- **各 Phase は Green で終わる**: 全ての Phase の最後で `bin/rails test` が通ることを確認
- **ジェネレータの判断**: Phase 2 で生成内容を確認し、適切な方針を選択する
- **CI/CD 対応**: テスト環境での `raise = true` により、CI/CD でN+1が自動検出される
