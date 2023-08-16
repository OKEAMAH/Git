FROM registry.gitlab.com/tezos/tezos/debug:amd64_pec_bench_dockerfile AS builder

FROM node:18.10 AS benchmark
# FROM  builder AS benchmark

# ARG USER=tezos
ARG USER=node

# copy files and binaries
WORKDIR /home/${USER}
RUN mkdir -p kernel
RUN mkdir -p ressources
RUN mkdir -p scripts
RUN mkdir -p output

#libev4 is necessary for the chunker
RUN apt-get update && apt-get install -y \
    libev4 \
    vim \
    && rm -rf /var/lib/apt/lists/*
# USER root
# RUN apk add --update nodejs npm vim gcompat
# USER tezos

# environment variables
ENV NODE_ENV=production
ENV EXTERNAL_RESSOURCES=/home/${USER}/ressources
ENV OUTPUT=/home/${USER}/output

# bust the cache (only necessary during docker dev)
ADD https://google.com cache_bust

# install scripts deps
COPY --chown=${USER}:nogroup src/kernel_evm/benchmarks/package*.json .
RUN npm install

# copy scripts FROM LOCAL
COPY --chown=${USER}:nogroup src/kernel_evm/benchmarks/scripts scripts
COPY --chown=${USER}:nogroup --chmod=765 src/kernel_evm/benchmarks/docker/command.sh .

COPY --chown=${USER}:nogroup octez_evm_chunker.exe /usr/local/bin/

# copy a statically version of the smart-rollup-installer
# compiled withcargo build --target=x86_64-unknown-linux-gnu
COPY --chown=${USER}:nogroup src/kernel_sdk/target/x86_64-unknown-linux-gnu/debug/smart-rollup-installer /usr/local/bin/

# copy external binaries FROM BUILDER IMAGE
# COPY --chown=${USER}:nogroup --from=builder /usr/local/bin/octez-evm-chunker /usr/local/bin/
COPY --chown=${USER}:nogroup --from=builder /usr/local/bin/octez-smart-rollup-wasm-debugger /usr/local/bin/
# COPY --chown=${USER}:nogroup --from=builder /usr/local/bin/smart-rollup-installer /usr/local/bin/

# copy external ressources FROM LOCAL
COPY --chown=${USER}:nogroup src/kernel_evm/target/wasm32-unknown-unknown/release/evm_kernel.wasm ressources/
COPY --chown=${USER}:nogroup src/kernel_evm/config/benchmarking.yaml ressources/

ENTRYPOINT [""]
CMD ["./command.sh"]