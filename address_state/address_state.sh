#!/bin/bash

NAME=$1
ADDRESS=$2
DENOM=$3
METRIC_FILE=$4
NODE_API_URL=${5:-"http://localhost:1317"}

cd $(dirname "$0")

network_up_and_synced () {
    local NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" ${NODE}/syncing)

    if (( $NODE_STATUS_CODE != 200 )); then
        exit 1 # Node is not reacahble
    fi

    local SYNCING_STATUS=$(curl -s ${NODE}/syncing)
    local CHAIN_SYNC_STATE=$(echo $CHAIN_STATUS | jq '.syncing')
    if [[ "$CHAIN_SYNC_STATE" == "true" ]]
    then
        exit 2 # Node is catching up
    fi
}

network_up_and_synced $NODE_API_URL

ADDRESS_STATE=$(curl -s ${NODE_API_URL}/bank/balances/${ADDRESS} | \
    /usr/bin/jq -r ".result[] | select(.denom | contains(\"${DENOM}\")).amount")


echo "opentech_address_state{name=\"${NAME}\", address=\"${ADDRESS}\", denom=\"${DENOM}\"} $ADDRESS_STATE" >> $METRIC_FILE