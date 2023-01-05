FROM ubuntu as ubuntu-base
RUN apt update -yq && \
    apt install curl -yq && \
    apt install git binaryen g++ build-essential make llvm libudev-dev pkg-config libssl-dev libclang-dev libprotobuf-dev protobuf-compiler -yq

FROM ubuntu-base as contractui
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt -y install nodejs 
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update -yq && apt install yarn -yq
RUN git clone https://github.com/paritytech/contracts-ui.git
WORKDIR /contracts-ui
RUN yarn
EXPOSE 8081
ENTRYPOINT [ "yarn", "start", "--host" ]

FROM ubuntu-base as rust-base
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

FROM rust-base as contractbuilding
RUN rustup default stable
RUN rustup update
RUN rustup update nightly
RUN rustup target add wasm32-unknown-unknown --toolchain nightly
RUN rustup show
RUN rustup +nightly show
RUN cargo install cargo-dylint dylint-link
RUN cargo install cargo-contract --locked
RUN rustup component add rustfmt
RUN rustup component add rust-src --toolchain nightly
RUN rustup target add wasm32-unknown-unknown --toolchain nightly

FROM rust-base as substratenode
RUN rustup default stable
RUN rustup update
RUN rustup update nightly
RUN rustup target add wasm32-unknown-unknown --toolchain nightly
RUN rustup show
RUN rustup +nightly show
RUN cargo install cargo-dylint dylint-link
RUN cargo install cargo-contract --locked
RUN rustup component add rustfmt
RUN git clone https://github.com/substrate-developer-hub/substrate-node-template
WORKDIR /substrate-node-template 
RUN git switch -c my-branch-v0.9.29
RUN cargo build --package node-template --release
RUN rustup component add rust-src --toolchain nightly
RUN rustup target add wasm32-unknown-unknown --toolchain nightly
RUN cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git --tag v0.23.0 --force --locked
EXPOSE 9933 9944 9615
#ENTRYPOINT ["./target/release/node-template", "--dev", "--unsafe-rpc-external" ]
ENTRYPOINT [ "/usr/local/cargo/bin/substrate-contracts-node", "--dev", "--unsafe-ws-external", "--rpc-cors", "all" ]
