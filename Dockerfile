# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry

EXPOSE 8545
EXPOSE 30303
EXPOSE 30303/udp

# Copy our source code into the container
WORKDIR /app

# Build and test the source code
COPY . .
RUN forge build
RUN forge test

ENV PRIVATE_KEY=""
ENV RPC_URL=""


# ENTRYPOINT ["sh", "-c", "PRIVATE_KEY=$PRIVATE_KEY forge script --rpc-url $RPC_URL ./script/DeployBaseChain.s.sol --broadcast"]
ENTRYPOINT ["sh", "./entry.sh"]
