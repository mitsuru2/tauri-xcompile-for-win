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
    curl \
    ca-certificates \
    llvm lld clang build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js
# - Node.js: https://nodejs.org/ja/about/previous-releases
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash \
    && apt-get install -y nodejs


# デフォルト動作 (Do nothing)
CMD ["sleep", "infinity"]
