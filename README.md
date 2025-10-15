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
