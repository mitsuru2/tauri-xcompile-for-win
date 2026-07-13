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
# - cargo-xwin: Windows クロスコンパイル用ランナー。
#               Tauri は Windows ターゲットとして MSVC (x86_64-pc-windows-msvc) を正式サポートしているため。
#               llvm-ar/lld-link 等は apt 版インストール済のため rustup component add での導入は不要。
# - cargo-deny: ライセンス監査 (GPL系コピーレフトライセンスのクレートが依存関係に
#               紛れ込んでいないかを src-tauri/deny.toml の許可リストでチェックする
RUN rustup target add x86_64-pc-windows-msvc
USER node
RUN cargo install --locked cargo-xwin cargo-deny \
    && mkdir -p /app/.cache/cargo-xwin
USER root

# ポート設定
# 4200, 4000: for Angular
EXPOSE 4200 4000

# 環境変数設定 (固定)
# - NG_CLI_ANALYTICS: Angular メトリクスデータ送信プロンプト抑制
# - XWIN_CACHE_DIR: ダウンロードした Windows SDK/CRT (約1GB) のキャッシュ先を固定。
ENV NG_CLI_ANALYTICS=false
ENV XWIN_CACHE_DIR=/app/.cache/cargo-xwin

# デフォルト動作 (Do nothing)
CMD ["sleep", "infinity"]
