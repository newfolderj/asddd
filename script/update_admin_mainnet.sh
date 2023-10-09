#!/bin/bash
set -a
source ./script/.processing.mainnet.env
source ./script/.auth.mainnet.env
set +a

# Ensure all required environment variables are set
REQUIRED_VARS=("ETH_RPC_URL" "BSC_RPC_URL" "ARB_RPC_URL" "MATIC_RPC_URL" "PRIVATE_KEY")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set!"
        exit 1
    fi
done

script_files=(
#   "processing/2_UpdateAdmin.s.sol"
#   "asset/5_UpdateAdmin.s.sol"
  "asset/5_UpdateAdmin.s.sol"
#   "asset/5_UpdateAdmin.s.sol"
)

rpc_urls=(
#   $ARB_RPC_URL
  $MATIC_RPC_URL
#   $BSC_RPC_URL
#   $ETH_RPC_URL
)

auth_files=(
#   "./script/.auth.mainnet.env"
  "./script/.asset.matic_mainnet.env"
#   "./script/.asset.bsc_mainnet.env"
#   "./script/.asset.eth_mainnet.env"
)


# Export the PRIV_KEY
export PRIVATE_KEY

for index in ${!script_files[*]}; do
  script_file=${script_files[$index]}
  rpc_url=${rpc_urls[$index]}
  auth_file=${auth_files[$index]}
  source $auth_file
  forge script script/deploy/$script_file --rpc-url $rpc_url -vvvv

  if [ $? -eq 0 ]; then
    forge script script/deploy/$script_file --rpc-url $rpc_url --broadcast  --legacy --slow --gas-limit 100000000

    if [ $? -ne 0 ]; then
      echo "Broadcasting $script_file failed"
      exit 1
    fi
  else
    echo "Simulating $script_file failed"
    exit 1
  fi
done
