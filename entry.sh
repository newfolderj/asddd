#!/bin/bash

anvil --host 0.0.0.0 &
sleep 5
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" forge script --rpc-url http://127.0.0.1:8545 script/DeployBaseChain.s.sol --broadcast
# Let this container stay running
sleep infinity
