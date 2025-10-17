# trial-rails8

Rails 8 の学習用リポジトリです。

## 機能

- ブログ投稿システム（記事の予約投稿機能付き）
- コメント機能
- ユーザー認証（BCrypt）
- Solid Queue による Active Job の実行

## Active Job の監視

開発環境では、Active Job の実行状況を Web UI で確認できます。

http://localhost:3000/jobs

Mission Control Jobs を使用して、以下の情報を確認できます：

- ジョブの実行履歴
- キューの状態（実行中・待機中・完了・失敗）
- ジョブの詳細情報（引数、実行時間、エラーなど）
- 失敗したジョブの手動再試行

## セットアップ

```bash
# 初期セットアップ（依存関係のインストール、データベース作成、サーバー起動まで）
bin/setup
```

## データベース構造

データベースのER図（Entity Relationship Diagram）は、以下のリンクから確認できます。

### メインアプリケーション

<a href="https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/schema.rb" target="_blank" rel="noopener noreferrer">ERDを表示</a>

アプリケーションのコアテーブル（users、posts、comments など）の構造とリレーションシップを確認できます。

### Solid Queue（Active Job）

<a href="https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/queue_schema.rb" target="_blank" rel="noopener noreferrer">ERDを表示</a>

Active Job の内部構造（ジョブキュー、実行状態、スケジューリングなど）を確認できます。

---

Liam ERDを使用して、データベースのテーブル構造とリレーションシップをインタラクティブに閲覧できます。
