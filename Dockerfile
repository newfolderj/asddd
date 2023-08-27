# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry

RUN apk update && apk add bash jq

EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp

# Copy our source code into the container
WORKDIR /app

# Build and test the source code
COPY . .
RUN forge build
RUN forge test

ENV ETH_RPC_URL=
ENV BSC_RPC_URL=
ENV ARB_RPC_URL=
ENV MATIC_RPC_URL=
ENV PRIVATE_KEY=

# Make the deploy script executable
RUN chmod +x ./script/deploy_testnet.sh

# Set the script as the entry point
ENTRYPOINT ["/bin/bash", "-c", "./script/deploy_testnet.sh"]
