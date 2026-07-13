# syntax=docker/dockerfile:1

# ベースイメージ選択
# - Docker Hub (Rust): https://hub.docker.com/_/rust
# - Rust: https://blog.rust-lang.org/releases/
# - Debian: https://wiki.debian.org/DebianReleases#Current_Debian_Releases_and_repositories
FROM rust:1-slim-trixie

# 標準ツール
# LLVM系: ビルドツールチェイン (clang/lld/llvm は Tauri の Windows クロスコンパイル (cargo-xwin) でも使用)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    sudo \
    curl \
    ca-certificates \
    llvm lld clang build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js
# - Node.js: https://nodejs.org/ja/about/previous-releases
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash \
    && apt-get install -y nodejs

# DevContainer拡張によりコンテナ実行時にバインドマウントされるため、イメージにソースコードはコピーしない。
# COPY . .

# ワークスペース設定
WORKDIR /app

# 非ルートユーザーへ変更
# - 'node' ユーザー定義追加
# - ユーザーがパスワードなしで sudo コマンドを使えるようにする
# - ワークスペース所有者変更
RUN useradd -m -u 1000 -s /bin/bash node \
    && mkdir -p /etc/sudoers.d \
    && echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node \
    && mkdir -p /app \
    && chown -R node:node /app

# NPMパッケージのインストール
# - Tauri v2 の CLI/API はバージョン管理のため、CargoではなくNPM経由でインストールする。
COPY --chown=node:node package*.json ./
USER node
RUN npm ci
USER root

# Tauri v2 Windows クロスコンパイル用ツールチェイン
# - このコンテナ (Linux) では Windows 向け exe の生成のみを行う。
#   Windows インストーラー (NSIS/MSI) は作成しないため、NSIS 等は導入しない。
#   インストーラーは別途 Inno Setup (Windows側) で作成する想定。
# - Tauri は Windows ターゲットとして MSVC (x86_64-pc-windows-msvc) を正式サポートしているため、
#   GNU (mingw-w64) ではなく cargo-xwin (clang/lld + Windows SDK/CRT の自動取得) を使う。
# - cargo-xwin は llvm-ar/lld-link 等を必要とするが、上記で導入済みの apt 版 llvm/lld/clang
#   (PATH上にある) で満たされるため、rustup component add llvm-tools は導入しない
RUN rustup target add x86_64-pc-windows-msvc
USER node
RUN cargo install --locked cargo-xwin \
    && mkdir -p /app/.cache/cargo-xwin
USER root

# ポート設定
# 4200, 4000: for Angular
EXPOSE 4200 4000

# 環境変数設定 (固定)
# - Angular メトリクスデータ送信プロンプト抑制
ENV NG_CLI_ANALYTICS=false
# - cargo-xwin: ダウンロードした Windows SDK/CRT (約1GB) のキャッシュ先を固定。
#   ユーザー名変更の影響を受けないよう /home/<user> 配下ではなく WORKDIR (/app) 配下に置く。
#   devcontainer.json 側でこのパスを名前付きボリュームにマウントし、
#   コンテナ再構築 (Rebuild Container) をまたいで再ダウンロードを防ぐ。
ENV XWIN_CACHE_DIR=/app/.cache/cargo-xwin

# デフォルト動作 (Do nothing)
CMD ["sleep", "infinity"]
