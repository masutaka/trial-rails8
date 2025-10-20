# docs/plan-for-issue-21.md レビュー

## 指摘事項
- **重大** docs/plan-for-issue-21.md:41-49 `turbo_frame_tag "new_comment"` でフォームを包む一方、フォームに `data: { turbo_frame: "comments" }` を付けると送信結果がコメント一覧フレームに描画され、フォーム側フレームが更新されません。成功時にフォームを初期化できず、失敗時もエラー表示がコメント一覧側に流れてしまうため、`create` アクションのレスポンス方針（両フレーム更新）と矛盾します。`render turbo_stream:` などでフォーム用フレームと一覧フレームを個別に更新する設計に改める必要があります。
- **重大** docs/plan-for-issue-21.md:59-68 `turbo_frame_tag dom_id(comment)` を使うだけでは編集リンクが別ページに遷移するままです。`_comment.html.erb` の編集リンクに `data: { turbo_frame: dom_id(comment) }`（または `link_to edit_comment_path(comment), data: { turbo_frame: dom_id(comment) }`）を追加しないと、`GET /comments/:id/edit` がフレーム内に読み込まれず計画が成立しません。リンクの調整を明記してください。
- **中** docs/plan-for-issue-21.md:78-85 削除ボタンへ `data: { turbo_frame: dom_id(comment) }` を付けても、レスポンスで空のフレームを返すだけでは DOM 上に空フレームが残ります。Turbo Stream の `remove` を使う方針に決め、ボタン側は `data: { turbo_method: :delete }` のみにして `destroy` から `render turbo_stream: turbo_stream.remove(dom_id(@comment))` を返す、など一貫した削除ストーリーにしてください。
- **中** docs/plan-for-issue-21.md:95-101 コメント数更新で Turbo Frame と Stimulus の二択を併記していますが、計画としてどちらを採用するか決めないと作業スコープとテストケースが曖昧になります。Turbo Stream に揃えるなど、手段を一本化してください。
- **軽微** docs/plan-for-issue-21.md:108-119 テスト計画が既存コントローラテストの修正に偏り、ユーザー操作と画面遷移抑止を検証するシステムテストを「必要に応じて」としている点が TDD の観点で弱いです。コメント投稿/編集/削除がページリロード無しで完了するシナリオを先にシステムテストとして追加する方針を明示すると安心です。

## オープンクエスチョン
- コメント作成成功時にフォームをクリアして再表示する想定でしょうか？もしそうであれば、フォーム用 Turbo Frame をどう更新するか（`render turbo_stream: turbo_stream.replace("new_comment", ...)` など）を計画に追記してもらえると実装が迷わなくなります。

