#!/bin/bash

# Ensure all required environment variables are set
# REQUIRED_VARS=("ETH_RPC_URL" "BSC_RPC_URL" "ARB_RPC_URL" "MATIC_RPC_URL" "PRIVATE_KEY")

# for var in "${REQUIRED_VARS[@]}"; do
#     if [ -z "${!var}" ]; then
#         echo "Error: $var is not set!"
#         exit 1
#     fi
# done

# Function to check the last command's status
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error executing script: $1"
        exit 1
    fi
}

# Running scripts sequentially
# ./script/mainnet_1_deploy_processing_chain.sh
# check_status "./script/mainnet_1_deploy_processing_chain.sh"

# ./script/mainnet_2_deploy_eth.sh
# check_status "./script/mainnet_2_deploy_eth.sh"

# ./script/mainnet_3_deploy_matic.sh
# check_status "./script/mainnet_3_deploy_matic.sh"

# ./script/mainnet_4_deploy_bsc.sh
# check_status "./script/mainnet_4_deploy_bsc.sh.sh"

# Generate JSON file of env vars
# Read from the source file
eth="script/deploy/chains/1/assetChainContracts.json"
bsc="script/deploy/chains/56/assetChainContracts.json"
matic="script/deploy/chains/137/assetChainContracts.json"
arb="script/deploy/chains/42161/processingChainContracts.json"

# Parse the values from the source file using jq
eth_asset_manager=$(jq -r '.manager' "$eth")
bsc_asset_manager=$(jq -r '.manager' "$bsc")
matic_asset_manager=$(jq -r '.manager' "$matic")
arb_processing_manager=$(jq -r '.manager' "$arb")
arb_rollup=$(jq -r '.rollup' "$arb")
eth_portal=$(jq -r '.portal' "$eth")
bsc_portal=$(jq -r '.portal' "$bsc")
matic_portal=$(jq -r '.portal' "$matic")
arb_staking=$(jq -r '.staking' "$arb")

# Construct a new JSON and write it to the desired file
jq -n --arg eth_asset_manager "$eth_asset_manager" --arg eth_portal "$eth_portal" \
--arg bsc_asset_manager "$bsc_asset_manager" --arg bsc_portal "$bsc_portal" \
--arg matic_asset_manager "$matic_asset_manager" --arg matic_portal "$matic_portal" \
--arg arb_processing_manager "$arb_processing_manager" --arg arb_rollup "$arb_rollup" \
--arg arb_staking "$arb_staking" \
'{
    "ETH_ASSET_MANAGER": $eth_asset_manager,
    "ETH_ASSET_CUSTODY": $eth_portal,
    "BSC_ASSET_MANAGER": $bsc_asset_manager,
    "BSC_ASSET_CUSTODY": $bsc_portal,
    "MATIC_ASSET_MANAGER": $matic_asset_manager,
    "MATIC_ASSET_CUSTODY": $matic_portal,
    "ARB_PROCESSING_MANAGER": $arb_processing_manager,
    "ROLLUP": $arb_rollup,
    "STAKING": $arb_staking
}' > contract_address_env_vars.json

cat contract_address_env_vars.json

# Notify when done
echo "All scripts executed successfully!"
