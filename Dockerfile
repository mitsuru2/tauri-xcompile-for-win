# syntax=docker/dockerfile:1

# ベースイメージ選択
# - Docker Hub (Rust): https://hub.docker.com/_/rust
# - Rust: https://blog.rust-lang.org/releases/
# - Debian: https://wiki.debian.org/DebianReleases#Current_Debian_Releases_and_repositories
FROM rust:1-slim-trixie

# 標準ツール
# LLVM系: ビルドツールチェイン
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
COPY --chown=node:node package*.json ./
USER node
RUN npm ci
USER root

# ポート設定
# 4200, 4000: for Angular
EXPOSE 4200 4000

# 環境変数設定 (固定)
# - Angular メトリクスデータ送信プロンプト抑制
ENV NG_CLI_ANALYTICS=false

# デフォルト動作 (Do nothing)
CMD ["sleep", "infinity"]
