# Issue #31: Rails 8.0.x から Rails 8.1.x へアップデート - 実装計画

## 概要

Rails 8.0.3 から Rails 8.1.x へアップデートする。Rails 8.1は500以上の貢献者による2,500コミットの成果で、Active Job Continuations、Structured Event Reporting、Local CIなどの新機能を含む。

**主要な新機能**:
- Active Job Continuations: 長時間ジョブの段階的実行とリスタート時の継続
- Structured Event Reporting: `Rails.event.notify()`による構造化イベント
- Local CI: `config/ci.rb`と`bin/ci`によるローカルCI実行
- スキーマカラムのアルファベット順ソート: `schema.rb`の一貫性向上

## 設計上の決定事項

### アップデート方針

1. **段階的アップデート**: Gemfile更新 → bundle update → テスト実行の順で進める
2. **schema.rb変更の扱い**: カラムがアルファベット順にソートされるため、差分は意図的な変更として扱う
3. **新機能の採用**: 今回のアップデートでは新機能は使用せず、既存機能の維持を優先
4. **load_defaults**: `config.load_defaults 8.0`のまま維持（8.1固有の新デフォルト設定を有効化しない）

### 破壊的変更への対応

Rails 8.1の主な破壊的変更:
- `schema.rb`のカラムがアルファベット順にソート（構造変更なし、順序のみ）
- JSON特殊文字エスケープの削除（U+2028、U+2029）
- finder順序エラー: order未指定のfirst/last呼び出しで例外発生（テスト時に確認）

## 実装手順

### Phase 1: Rails 8.1への更新

**目的**: Gemfile内のRailsバージョンを8.1系に更新し、依存gemを更新

**変更内容**:

1. `Gemfile`の4行目を変更:
   ```ruby
   gem "rails", "~> 8.1.0"
   ```
2. `bundle update rails`を実行してGemfile.lockを更新
3. 更新内容を確認:
   - Rails関連gem（actionpack、activerecordなど）が8.1系に更新されていること
   - 依存gemのバージョンが互換性のある範囲で更新されていること

**理由**:
- `~> 8.1.0`でRails 8.1系の最新パッチバージョンを自動取得
- `bundle update rails`でRails本体と直接依存するgemのみを更新
- 全gemを更新する`bundle update`は避け、影響範囲を最小化
- Gemfile更新と bundle update は1つの論理的な変更単位

**コミットメッセージ**: `chore: Update Rails from 8.0.x to 8.1.x`

### Phase 2: rails app:update の実行

**目的**: Rails 8.1の設定ファイルやイニシャライザを確認・更新

**変更内容**:

1. `bin/rails app:update`を実行
2. 対話的なプロンプトで以下を確認:
   - 新しい設定ファイルやイニシャライザの有無
   - 既存ファイルとの差分
3. 必要に応じて差分をマージ（通常は大きな変更なし）

**理由**:
- Rails 8.1で追加された新しい設定やイニシャライザを確認
- `config.load_defaults 8.0`を維持するため、通常は大きな変更なし

**注意**: 変更がない場合はコミット不要

**コミットメッセージ（変更がある場合）**: `chore: Update configuration files with rails app:update`

### Phase 3: テストの実行と修正

**目的**: Rails 8.1への更新によるテスト失敗を確認・修正

**変更内容**:

1. `bin/rails test`を実行
2. テスト失敗がある場合は以下を確認:
   - finder順序エラー: `first`/`last`のorder未指定呼び出し → `order(id: :asc)`などを追加
   - JSON関連のテスト: 特殊文字エスケープの変更による差分
   - その他のdeprecation警告や例外
3. 必要に応じてコードを修正

**理由**:
- Rails 8.1の破壊的変更によるテスト失敗を早期発見
- finder順序エラーは明示的なorder指定を推奨する変更

**コミットメッセージ（修正がある場合）**: `fix: Resolve test failures after Rails 8.1 upgrade`

### Phase 4: schema.rb の更新

**目的**: データベーススキーマをダンプしてカラムのアルファベット順ソートを反映

**変更内容**:

1. `bin/rails db:migrate`を実行（マイグレーションがない場合でもschema.rbが更新される）
2. `schema.rb`の差分を確認:
   - 各テーブルのカラムがアルファベット順にソートされていること
   - カラム定義自体に変更がないこと（順序のみ変更）

**理由**:
- Rails 8.1ではschema.rbのカラムがアルファベット順にソート（[#53281](https://github.com/rails/rails/pull/53281)）
- マシン間での一貫性を保ち、マイグレーション順序によるdiffノイズを削減
- 構造的な変更はなく、順序のみの変更

**コミットメッセージ**: `chore: Update schema.rb with alphabetically sorted columns (Rails 8.1)`

### Phase 5: Rubocop の実行と修正

**目的**: コーディング規約違反がないことを確認

**変更内容**:

1. `bin/rubocop`を実行
2. エラーがある場合は`bin/rubocop -a`で自動修正を試みる
3. 自動修正できないエラーは手動で修正

**理由**:
- プロジェクトのコーディング規約を維持
- CLAUDE.mdのコミット前要件に従う

**コミットメッセージ（修正がある場合）**: `style: Fix rubocop violations after Rails 8.1 upgrade`

### Phase 6: CI の動作確認

**目的**: GitHub Actions CIでテストが通ることを確認

**変更内容**:

1. プルリクエストを作成してCIを実行
2. 以下のジョブが成功することを確認:
   - `scan_ruby`: Brakemanによるセキュリティスキャン
   - `scan_js`: Importmapの脆弱性スキャン
   - `lint`: Rubocopによるリント
   - `test`: テスト実行（db:test:prepare、test、test:system）
3. 失敗した場合は原因を調査して修正

**理由**:
- ローカル環境とCI環境での動作確認
- テスト環境での互換性を検証

**注意**: この Phase はコミットを作成しない（確認作業のみ）

### Phase 7: README.md の更新

**目的**: Rails 8.1へのアップデートをREADMEに反映

**変更内容**:

1. `README.md`の**技術スタック**セクションを更新:
   - `Rails 8.0` → `Rails 8.1`
2. 必要に応じて新機能の説明を追加（今回は不要の想定）

**理由**:
- プロジェクトの技術スタックを最新の状態に保つ
- ボリュームを増やさず、既存テキストの更新のみ

**コミットメッセージ**: `docs: Update Rails version to 8.1 in README`

## 考慮事項

### 互換性

- **Ruby バージョン**: Rails 8.1はRuby 3.2.0以上が必要（現在のプロジェクトで確認済み）
- **Gem 互換性**: `solid_queue`、`mission_control-jobs`など既存gemがRails 8.1に対応していること
- **データベース**: MySQL 8.0との互換性は維持

### 新機能の採用タイミング

今回のアップデートでは以下の新機能は使用しない:
- Active Job Continuations: 長時間ジョブがない場合は不要
- Structured Event Reporting: カスタムイベント報告が必要になった時点で検討
- Local CI: 既存のGitHub Actions CIで十分

### schema.rb の変更

- カラムのアルファベット順ソートは大きな差分を生むが、構造的な変更はない
- 今後のマイグレーションでもカラム順序が一貫するため、長期的にはメリット
- `structure.sql`への切り替えは不要（カラム順序を厳密に保つ必要性なし）

## 受け入れ基準

- [ ] Gemfileが`rails ~> 8.1.0`に更新されていること
- [ ] `bundle update rails`が実行され、Gemfile.lockが更新されていること
- [ ] `bin/rails test`が全て通ること
- [ ] `bin/rubocop`がエラーなく通ること
- [ ] GitHub Actions CIの全ジョブが成功すること
- [ ] `schema.rb`のカラムがアルファベット順にソートされていること
- [ ] README.mdのRailsバージョンが8.1に更新されていること

## 注意事項

- **各 Phase は Green で終わる**: 全ての Phase で`bin/rails test`が通ることを確認
- **schema.rb の差分**: カラムのアルファベット順ソートは意図的な変更
- **新機能は使用しない**: 今回は既存機能の維持を優先
- **load_defaults**: `8.0`のまま維持し、8.1固有のデフォルト設定は有効化しない

## 参考資料

- [Rails 8.1リリースノート](https://rubyonrails.org/2025/10/22/rails-8-1)
- [Rails 8.1のマイナーフィーチャー](https://gist.github.com/willnet/35b34f5f937683e69c62fd74c250a4a8)
- [Rails Upgrading Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails 8.1 スキーマソート PR #53281](https://github.com/rails/rails/pull/53281)
