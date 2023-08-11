FROM node:18.10

# copy files and binaries
WORKDIR /home/node
RUN mkdir -p kernel
RUN mkdir -p ressources
RUN mkdir -p scripts
RUN mkdir -p output


#libev4 is necessary for the chunker
RUN apt-get update && apt-get install -y \
    libev4 \
    vim \
    && rm -rf /var/lib/apt/lists/*

# environment variables
ENV NODE_ENV=production
ENV EXTERNAL_RESSOURCES=/home/node/ressources
ENV OUTPUT=/home/node/output

# bust the cache
ADD https://google.com cache_bust

# install scripts deps
COPY --chown=node:nogroup src/kernel_evm/benchmarks/package*.json .
RUN npm install

# copy scripts
COPY --chown=node:nogroup src/kernel_evm/benchmarks/scripts scripts
COPY --chown=node:nogroup --chmod=765 src/kernel_evm/benchmarks/docker/command.sh .

# copy external binaries
COPY --chown=node:nogroup octez_evm_chunker.exe /usr/local/bin/
COPY --chown=node:nogroup octez-smart-rollup-wasm-debugger /usr/local/bin/
COPY --chown=node:nogroup src/kernel_sdk/target/release/smart-rollup-installer /usr/local/bin/

# copy external ressources
COPY --chown=node:nogroup src/kernel_evm/target/wasm32-unknown-unknown/release/evm_kernel.wasm ressources/
COPY --chown=node:nogroup src/kernel_evm/config/benchmarking.yaml ressources/

CMD ["./command.sh"]