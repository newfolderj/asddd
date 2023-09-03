#!/bin/bash
set -a
source ./script/.processing.mainnet.env
# Replace below with which asset chain is being deployed
source ./script/.asset.matic_mainnet.env
source ./script/.auth.mainnet.env
set +a

if [ -z "$ARB_RPC_URL" ]; then
  echo "ARB_RPC_URL environment variable is not set"
  exit 1
fi

if [ -z "$MATIC_RPC_URL" ]; then
  echo "MATIC_RPC_URL environment variable is not set"
  exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
  echo "PRIVATE_KEY environment variable is not set"
  exit 1
fi

script_files=(
  # "settlement/1_DepositAssets.s.sol"
  "settlement/2_SubmitSettlement.s.sol"
)
rpc_urls=(
  # $MATIC_RPC_URL
  $ARB_RPC_URL
)

# Export the PRIV_KEY
export PRIVATE_KEY

for index in ${!script_files[*]}; do
  script_file=${script_files[$index]}
  rpc_url=${rpc_urls[$index]}
  forge script script/deploy/$script_file --rpc-url $rpc_url -vvvv

  if [ $? -eq 0 ]; then
    forge script script/deploy/$script_file --rpc-url $rpc_url --broadcast --slow --legacy

    if [ $? -ne 0 ]; then
      echo "Broadcasting $script_file failed"
      exit 1
    fi
  else
    echo "Simulating $script_file failed"
    exit 1
  fi
done
