# コメント機能で Turbo Streams と Turbo Frames を使い分ける理由

## 概要

このドキュメントでは、コメント機能の実装において Turbo Streams と Turbo Frames をなぜ使い分けているのか、その技術的な理由を説明します。

## Turbo Frames と Turbo Streams の違い

### Turbo Frames の特性

- **1対1の置き換え**が基本動作
- フレーム内のリンク/フォーム送信 → 同じIDのフレームだけを更新
- **ナビゲーションスコープを限定**する
- **適している用途**: インライン編集のような「その場で表示と編集を切り替える」操作

### Turbo Streams の特性

- **複数箇所を同時に更新**できる
- 柔軟なアクション: `prepend`、`append`、`replace`、`update`、`remove`
- 1回のレスポンスで**ページの複数の部分を独立して操作**可能
- **適している用途**: 複数要素の追加/削除/更新を一度に行う操作

## コメント機能での使い分け

| 操作 | 使用技術 | 理由 |
|------|---------|------|
| **編集** | Turbo Frames | 単一エリアの状態遷移（表示⇄編集フォーム） |
| **投稿** | Turbo Streams | 複数箇所の同時更新（フォームクリア + 一覧追加 + カウント更新） |
| **削除** | Turbo Streams | 要素の完全削除 + コメント数の更新 |

### 1. コメント編集で Turbo Frames を使う理由

**要件**:
- 編集リンクをクリック → その場に編集フォームを表示
- 更新ボタンをクリック → その場に更新されたコメントを表示

**なぜ Turbo Frames か**:
- **単一のコンテンツエリア**の状態遷移（表示 ⇄ 編集）
- フレーム内で完結する操作
- 他の要素に影響を与えない

### 2. コメント投稿で Turbo Streams を使う理由

**要件**:
- フォームを送信 → フォームをクリア
- 新しいコメントをコメント一覧に追加
- コメント数を更新

**なぜ Turbo Streams か**:
- **3箇所を同時に更新**する必要がある
- Turbo Frames だけでは実現困難（1対1の置き換えのみ）

**コード例**:
```ruby
render turbo_stream: [
  turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
  turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post }),
  turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
]
```

### 3. コメント削除で Turbo Streams を使う理由

**要件**:
- コメントをDOMから完全に削除
- コメント数を更新

**なぜ Turbo Streams か**:
- `remove` アクションで要素を**完全に削除**（空のフレームを残さない）
- 同時にコメント数も更新

**コード例**:
```ruby
render turbo_stream: [
  turbo_stream.remove(dom_id(@comment)),
  turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)
]
```

## まとめ

**選択の基準**:
- **更新箇所が1箇所** → Turbo Frames
- **更新箇所が複数** → Turbo Streams
- **要素の完全削除** → Turbo Streams の `remove`
- **状態の切り替え**（表示⇄編集） → Turbo Frames

この使い分けにより、技術スタックを Hotwire に統一しつつ、各操作に最適なアプローチを選択しています。

## 関連ドキュメント

- [実装計画の詳細](./plan-for-issue-21.md)
- [Turbo Frames 公式ドキュメント](https://turbo.hotwired.dev/handbook/frames)
- [Turbo Streams 公式ドキュメント](https://turbo.hotwired.dev/handbook/streams)
