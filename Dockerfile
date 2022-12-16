FROM ubuntu as rusty-base
RUN apt update -yq && \
    apt install git binaryen cmake pkg-config libssl-dev libclang-dev libprotobuf-dev protobuf-compiler curl -yq
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=%%RUST-VERSION%%
RUN set -eux; \
    url="https://sh.rustup.rs"; \
    curl "$url" -o rustup-init; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal;\
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

FROM rusty-base
RUN cargo install cargo-dylint dylint-link
RUN cargo install cargo-contract --locked
RUN cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git --tag v0.17.0 --force --locked
RUN git clone https://github.com/substrate-developer-hub/substrate-node-template
RUN cd substrate-node-template
RUN git switch -c my-branch-v0.9.29
RUN cargo build --package node-template --release
RUN rustup component add rust-src --toolchain nightly
RUN rustup target add wasm32-unknown-unknown --toolchain nightly
