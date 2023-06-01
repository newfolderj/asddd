#!/bin/bash

anvil --host 0.0.0.0 &
sleep 5
forge script --rpc-url http://127.0.0.1:8545 script/DeployBaseChain.s.sol --broadcast
# Let this container stay running
sleep infinity
