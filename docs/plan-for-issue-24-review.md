# Issue #24 実装計画レビュー

## 指摘事項

- `docs/plan-for-issue-24.md` Phase 3: コメント数更新のブロードキャストをコントローラに追加する案は、ビジネスロジックをモデルへ集約するというプロジェクト方針（MVC、Tell, Don't Ask）に反しており、今後の保守性低下が懸念されます。モデルあるいはサービス層に寄せる設計を検討してください。
    - WIP 
- 同 Phase 3 の `Turbo::StreamsChannel.broadcast_update_to` が現在の依存バージョンで利用可能か確認が必要です。利用不可の場合は `broadcast_replace_to` など既存のAPIに置き換える必要があります。
    - WIP 
- `broadcast_update_to` で更新対象にしている `comment_count_#{@post.id}` 向けのDOM要素は `app/views/posts/show.html.erb` に既に存在しますが、`Turbo Stream` の更新内容が単なる文字列 `"(#{@post.comments.count})"` のままだとスペースやラベルを維持できません。ビュー側の表記ゆれ（例: 先行するスペースやテキスト）を壊さないようにHTML全体を再描画する方法を検討すべきです。
    - WIP 
- Phase 4 でテストを最後に追加する流れは、t-wada式TDD（Red→Green→Refactor）に反しており、事前にテストを用意するステップが欠落しています。テストを起点に実装を進める計画へ修正してください。
    - WIP 

## 確認したい点

- `broadcasts_to :post` による既存コメント一覧へのappend/replace/remove動作が、現在の`app/views/posts/show.html.erb`の構造（`div#comments`直下に`render @post.comments`）と整合することをどうやって検証しますか？ 既存フラグメントのDOM構造と Turbo の既定 target が噛み合わない場合の調整方法もあわせて教えてください。
    - WIP 
- コメント数をブロードキャストするトリガーは `Comment` モデルの `after_commit` などへ移す予定はありますか？ Controller依存のままだと、将来別のエントリポイントからコメント数が変化した際に同期漏れが発生しそうです。
    - WIP 
