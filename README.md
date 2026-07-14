# tauri-xcompile-for-win

Angular + Tauri v2 で構築する Windows 向けネイティブアプリの開発環境を、Linux 上からのクロスコンパイルで実現するための PoC (Proof of Concept) です。

## 目的

Tauri アプリの Windows 向けビルドは、通常 Windows 環境（実機または CI）を必要とします。しかし本プロジェクトでは [cargo-xwin](https://github.com/rust-cross/cargo-xwin) を用いることで、Linux コンテナ上から Windows (`x86_64-pc-windows-msvc`) 向けバイナリを直接クロスコンパイルします。

これにより次を狙います。

- 開発環境（Rust ツールチェイン・Node.js・クロスコンパイル用ツール群）を Dockerfile としてリポジトリ上で一括管理する
- 開発メンバーのローカル PC には DevContainer 経由で同一の環境を配信し、環境差異による問題を防ぐ
- GitHub Actions などの CI 環境にも同じコンテナイメージを配信し、Lint・テスト・ライセンスチェックを同一環境で実行する
- `cargo-deny` を導入し、Rust クレートの依存関係に GPL 系コピーレフトライセンスが意図せず混入するリスクに対応する

## 技術スタック

- フロントエンド: [Angular](https://angular.dev/) + [PrimeNG](https://primeng.org/)
- デスクトップアプリフレームワーク: [Tauri](https://tauri.app/) v2
- クロスコンパイル: [cargo-xwin](https://github.com/rust-cross/cargo-xwin)（Windows SDK/CRT を自動取得し、clang-cl/lld-link でリンク）
- 開発環境: Docker（`rust:1-slim-trixie` ベース）+ [Dev Containers](https://containers.dev/)

## 開発環境のセットアップ

本プロジェクトは [DevContainer](.devcontainer/devcontainer.json) での開発を前提としています。以下の環境を前提とします。

- Windows + WSL2 が有効化されていること
- WSL2 上に [Docker CE](https://docs.docker.com/engine/install/) がインストールされていること

セットアップ手順は次の通りです。

1. VS Code に [Remote Development 拡張機能パック](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) をインストールする（Dev Containers に加え、Remote - SSH など関連拡張が含まれています）
2. `.devcontainer/secrets.env` を用意する（`PRIMENG_LICENSE_KEY` などの秘匿情報。Git 管理対象外）
3. VS Code でプロジェクトのルートフォルダを開き、`F1` キーからコマンドパレットを開いて「Dev Containers: Open Folder in Container...」を選択し、コンテナを起動する

コンテナには以下がセットアップ済みです。

- Node.js / npm（フロントエンド依存関係、Tauri CLI）
- Rust ツールチェイン + `x86_64-pc-windows-msvc` ターゲット
- `cargo-xwin`（Windows クロスコンパイル用ランナー）
- `cargo-deny`（依存クレートの GPL 系ライセンス監査用）
- LLVM 系ツール（clang/lld）

コンテナイメージは [`Dockerfile`](Dockerfile) で定義されており、`main` ブランチへの変更時に GitHub Container Registry (`ghcr.io`) へ自動でパブリッシュされます（[`.github/workflows/publish-docker-image.yml`](.github/workflows/publish-docker-image.yml)）。CI のジョブもこのイメージをそのまま使用します。

## 開発サーバー

```bash
npm start
```

`http://localhost:4200/` でアプリが起動します。ソースコード変更時は自動でリロードされます。

## Windows 向けビルド（クロスコンパイル）

```bash
# リリースビルド
npm run tauri:build:release

# デバッグビルド
npm run tauri:build:debug
```

内部では [`scripts/tauri-build.sh`](scripts/tauri-build.sh) 経由で `tauri build --runner cargo-xwin --target x86_64-pc-windows-msvc` を実行し、Linux 上から Windows 向け実行ファイルを生成します。

## テスト・Lint・ライセンスチェック

```bash
# 単体テスト（Vitest）
npm test

# Lint
npm run lint

# ライセンスチェック（GPL系コピーレフトライセンスの混入を検知）
npm run ng:check:gpl      # npm (Angular) 依存関係
npm run tauri:check:gpl   # Rust (Tauri) 依存関係
```

これらは [`.github/workflows/basic-check.yml`](.github/workflows/basic-check.yml) により、push のたびに CI 上でも自動実行されます。

## ディレクトリ構成（抜粋）

```
.
├── Dockerfile              # 開発・CI 共通の開発環境イメージ定義
├── .devcontainer/          # VS Code Dev Containers 設定
├── .github/workflows/      # CI（Lint/テスト/ライセンスチェック、イメージパブリッシュ）
├── scripts/                # ビルド補助スクリプト
├── src/                    # Angular フロントエンドソース
└── src-tauri/               # Tauri (Rust) バックエンドソース
```

## ライセンス

[MIT License](LICENSE)
