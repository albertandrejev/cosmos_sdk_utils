#!/bin/bash

VALIDATOR_ADDR=$1
COIN=$2 #Use name from coingecko
REST_NODE=${3:-"http://localhost:1317"}
DENOM=${4:-1000000}

network_up_and_synced () {
    local REST_NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" ${REST_NODE}/node_info)

    if (( $NODE_STATUS_CODE != 200 )); then
        exit 1 # Node is not reacahble
    fi

    local CHAIN_SYNC_STATE=$(curl -s ${REST_NODE}/syncing | jq '.syncing')

    if [[ "$CHAIN_SYNC_STATE" == "true" ]]
    then
        exit 2 # Node is catching up
    fi

    local LATEST_BLOCK_TIME=$(curl -s ${REST_NODE}/blocks/latest  | jq -r '.block.header.time')

    local CONTROL_TIME=$(date -d "-180 seconds")
    local BLOCK_TIME=$(date -d "${LATEST_BLOCK_TIME}")

    if [[ "$BLOCK_TIME" < "$CONTROL_TIME" ]];
    then
        exit 3 # Block is in the past
    fi 
}

network_up_and_synced $REST_NODE

DELEGATION_AMOUNT=$(curl -s ${REST_NODE}/cosmos/staking/v1beta1/validators/${VALIDATOR_ADDR} | jq -r '.validator.tokens')

COIN_PRICE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=${COIN}&vs_currencies=usd" | \
        jq ".${COIN}.usd")

echo "${DELEGATION_AMOUNT} / ${DENOM} * $COIN_PRICE" | bc -l


