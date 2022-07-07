#!/bin/bash

PATH_TO_SERVICE=$1
VALIDATOR_ADDR=$2
NETWORK=$3
DENOM=$4
NODE=${5:-"http://localhost:26657"}

network_up_and_synced () {
    local NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" $NODE/status)

    if (( $NODE_STATUS_CODE != 200 )); then
        exit 1 # Node is not reacahble
    fi

    local CHAIN_STATUS=$(curl -s ${NODE}/status)
    local CHAIN_ID=$(echo $CHAIN_STATUS | jq -r '.result.node_info.network')

    local CHAIN_SYNC_STATE=$(echo $CHAIN_STATUS | jq '.result.sync_info.catching_up')
    if [[ "$CHAIN_SYNC_STATE" == "true" ]]
    then
        exit 2 # Node is catching up
    fi

    local LATEST_BLOCK_TIME=$(echo $CHAIN_STATUS | jq -r '.result.sync_info.latest_block_time')

    local CONTROL_TIME=$(date -d "-180 seconds")
    local BLOCK_TIME=$(date -d "${LATEST_BLOCK_TIME}")

    if [[ "$BLOCK_TIME" < "$CONTROL_TIME" ]];
    then
        exit 3 # Block is in the past
    fi 
}

network_up_and_synced $NODE

echo $(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDR --node ${NODE} -o json | \
    /usr/bin/jq ".commission[] | select(.denom | contains(\"${DENOM}\")).amount | tonumber")


