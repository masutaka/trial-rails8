# CLAUDE.md

## TDD での注意点

- テストはファイル単位で実行する
    - 例: "rails test test/models/post_test.rb"
- ルーティングのテストも書く
    - test/routing/

## コミット前の注意点

- "bin/rubocop" のエラーがないことを確認すること
    - エラーが発生したら "bin/rubocop -a" で修正を試みること
