# trial-rails8

Rails 8 の学習用リポジトリです。

## 機能

- ブログ投稿システム（記事の予約投稿機能付き）
- コメント機能
- ユーザー認証（BCrypt）
- Solid Queue による Active Job の実行

## セットアップ

依存関係のインストール、データベース作成、サーバー起動まで。

```bash
bin/setup
```

http://localhost:3000 から、アプリケーションにアクセスできます。

## Active Job の監視

開発環境では、Active Job の実行状況を Web UI で確認できます。

http://localhost:3000/jobs

Mission Control Jobs を使用して、以下の情報を確認できます：

- ジョブの実行履歴
- キューの状態（実行中・待機中・完了・失敗）
- ジョブの詳細情報（引数、実行時間、エラーなど）
- 失敗したジョブの手動再試行

## データベース構造

[Liam ERD](https://liambx.com/) でデータベースの ER 図をインタラクティブに閲覧できます。

### メインアプリケーション

[ERDを表示](https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/schema.rb)

アプリケーションのコアテーブル（users、posts、comments など）の構造とリレーションシップを確認できます。

### Solid Queue（Active Job）

[ERDを表示](https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/queue_schema.rb)

Active Job の内部構造（ジョブキュー、実行状態、スケジューリングなど）を確認できます。

### Solid Cable（Action Cable）

[ERDを表示](https://liambx.com/erd/p/github.com/masutaka/trial-rails8/blob/main/db/cable_schema.rb)

Action Cable の内部構造（WebSocketメッセージ、チャンネル、ブロードキャストなど）を確認できます。
