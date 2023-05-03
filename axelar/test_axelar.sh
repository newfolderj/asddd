#!/bin/bash
npx ts-node ./axelar/startChains.ts &
pid=$!
cleanup() {
    kill $pid
}
trap cleanup EXIT

# Wait for all Axelar contracts to be deployed
sleep 5

# Run Forge scripts to test cross-chain messaging
set -o allexport
source ./axelar/out/.2500
set +o allexport
forge script --rpc-url http://localhost:8545/0 script/axelar/01_DeployBaseChain.s.sol --broadcast

set -o allexport
source ./axelar/out/.2501
set +o allexport
forge script --rpc-url http://localhost:8545/1 script/axelar/02_DeployChildChain.s.sol --broadcast

set -o allexport
source ./axelar/out/.2500
set +o allexport
forge script --rpc-url http://localhost:8545/0 script/axelar/03_RelayStateRoot.s.sol --broadcast

sleep 1
forge script --rpc-url http://localhost:8545/1 script/axelar/04_CheckRelayedRoot.s.sol
forge script --rpc-url http://localhost:8545/0 script/axelar/05_CheckRelayAck.s.sol
