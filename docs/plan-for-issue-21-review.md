# docs/plan-for-issue-21.md レビュー by codex

## 指摘事項

- [ ] **重大** docs/plan-for-issue-21.md:41-49 `turbo_frame_tag "new_comment"` でフォームを包む一方、フォームに `data: { turbo_frame: "comments" }` を付けると送信結果がコメント一覧フレームに描画され、フォーム側フレームが更新されません。成功時にフォームを初期化できず、失敗時もエラー表示がコメント一覧側に流れてしまうため、`create` アクションのレスポンス方針（両フレーム更新）と矛盾します。`render turbo_stream:` などでフォーム用フレームと一覧フレームを個別に更新する設計に改める必要があります。
    - **Claude の意見**: 指摘は正しい。Turbo Stream を使って複数フレームを同時更新する設計に変更すべき。フォームから `data: { turbo_frame: "comments" }` を削除し、`create` アクションで `render turbo_stream: [turbo_stream.prepend("comments", ...), turbo_stream.replace("new_comment", ...)]` のように複数のストリームを返す実装にする。成功時はコメント一覧に新規コメントを追加しつつフォームをクリア、失敗時はフォーム内にエラーを表示できる。
- [ ] **重大** docs/plan-for-issue-21.md:59-68 `turbo_frame_tag dom_id(comment)` を使うだけでは編集リンクが別ページに遷移するままです。`_comment.html.erb` の編集リンクに `data: { turbo_frame: dom_id(comment) }`（または `link_to edit_comment_path(comment), data: { turbo_frame: dom_id(comment) }`）を追加しないと、`GET /comments/:id/edit` がフレーム内に読み込まれず計画が成立しません。リンクの調整を明記してください。
    - **Claude の意見**: 指摘は正しい。Turbo Frame 内のリンクは明示的にターゲットフレームを指定すべき。Phase 2 の変更内容に「編集リンクに `data: { turbo_frame: dom_id(comment) }` を追加」を明記する必要がある。これにより、編集リンククリック時に同じフレーム内で編集フォームが読み込まれる。
- [ ] **中** docs/plan-for-issue-21.md:78-85 削除ボタンへ `data: { turbo_frame: dom_id(comment) }` を付けても、レスポンスで空のフレームを返すだけでは DOM 上に空フレームが残ります。Turbo Stream の `remove` を使う方針に決め、ボタン側は `data: { turbo_method: :delete }` のみにして `destroy` から `render turbo_stream: turbo_stream.remove(dom_id(@comment))` を返す、など一貫した削除ストーリーにしてください。
    - **Claude の意見**: 指摘は正しい。Turbo Stream の `remove` を使う方針に統一すべき（計画書自体も「こちらの方が自然」と記載している）。削除ボタンに特別な `data` 属性は不要で、`destroy` アクションから `render turbo_stream: turbo_stream.remove(dom_id(@comment))` を返すだけで、DOM から要素が完全に削除される。Phase 1 で既に Turbo Stream を導入するので技術的にも一貫性がある。
- [ ] **中** docs/plan-for-issue-21.md:95-101 コメント数更新で Turbo Frame と Stimulus の二択を併記していますが、計画としてどちらを採用するか決めないと作業スコープとテストケースが曖昧になります。Turbo Stream に揃えるなど、手段を一本化してください。
    - **Claude の意見**: 指摘は正しい。Turbo Stream に統一すべき。Phase 1-3 で既に Turbo Stream を使用しているため、技術スタックを統一することで保守性と一貫性が向上する。また、サーバー側で正確なコメント数を計算して返せるため、クライアント側カウントの誤差もない。`create` と `destroy` アクションで `turbo_stream.update("comment_count_#{@post.id}", @post.comments.count.to_s)` を追加すれば実装できる。
- [ ] **軽微** docs/plan-for-issue-21.md:108-119 テスト計画が既存コントローラテストの修正に偏り、ユーザー操作と画面遷移抑止を検証するシステムテストを「必要に応じて」としている点が TDD の観点で弱いです。コメント投稿/編集/削除がページリロード無しで完了するシナリオを先にシステムテストとして追加する方針を明示すると安心です。
    - **Claude の意見**: システムテストは作らない方針であれば、コントローラテストを充実させることで対応可能。Phase 5 では、Turbo Stream レスポンスの詳細な検証（正しい turbo-stream タグが含まれているか、適切な action と target が指定されているか、レンダリング内容が正しいか）を行うテストを追加すべき。実際のブラウザでの画面遷移抑止は手動テストで確認する。コントローラテストでレスポンス内容を十分に検証すれば、品質は担保できる。

## オープンクエスチョン

- [ ] コメント作成成功時にフォームをクリアして再表示する想定でしょうか？もしそうであれば、フォーム用 Turbo Frame をどう更新するか（`render turbo_stream: turbo_stream.replace("new_comment", ...)` など）を計画に追記してもらえると実装が迷わなくなります。
    - **Claude の意見**: フォームはクリアして再表示すべき。理由は、連続投稿時の利便性、成功の視覚的フィードバック、標準的な UX。指摘1で述べた通り、Turbo Stream で `turbo_stream.replace("new_comment", partial: "comments/form", locals: { comment: Comment.new, post: @post })` を返すことで実現できる。`Comment.new` を渡すことでフォームが空の状態で再表示される。
