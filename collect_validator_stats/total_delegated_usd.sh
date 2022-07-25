#!/bin/bash

VALIDATOR_ADDR=$1
COIN=$2 #Use name from coingecko
REST_NODES_LIST_PATH=$3
DENOM=${4:-1000000}

if [ -z "$REST_NODES_LIST_PATH" ]
then
    echo "No list of REST nodes was provided"
    exit 4
fi

network_up_and_synced () {
    local REST_NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" ${REST_NODE}/node_info)

    if (( $NODE_STATUS_CODE != 200 )); then
        echo "Node is not reachable. Exiting..." >&2
        exit 1 # Node is not reachable
    fi

    local LATEST_BLOCK_TIME=$(curl -m 10 -s ${REST_NODE}/blocks/latest  | jq -r '.block.header.time')

    local CONTROL_TIME=$(date -d "-180 seconds")
    local BLOCK_TIME=$(date -d "${LATEST_BLOCK_TIME}")

    if [[ "$BLOCK_TIME" < "$CONTROL_TIME" ]];
    then
        echo "Block time is in past. Exiting..." >&2
        exit 3 # Block is in the past
    fi 
}

REST_NODES_LIST=$(cat $REST_NODES_LIST_PATH)
REST_NODES_AMOUNT=$(echo "${REST_NODES_LIST}" | jq 'length - 1')

RANDOM_NODE_IDX=$(shuf -i 0-${REST_NODES_AMOUNT} -n 1)

REST_NODE=$(echo "${REST_NODES_LIST}" | jq -r ".[${RANDOM_NODE_IDX}]")

echo "Using ${REST_NODE} node..." >&2

network_up_and_synced $REST_NODE

DELEGATION_AMOUNT=$(curl -m 10 -s ${REST_NODE}/cosmos/staking/v1beta1/validators/${VALIDATOR_ADDR} | \
    jq -r '.validator.tokens')

if [ $? -ne 0 ]
then
    echo "Unable to get delegations amount. Exiting..." >&2
    exit 5
fi

COIN_PRICE=$(curl -m 10 -s "https://api.coingecko.com/api/v3/simple/price?ids=${COIN}&vs_currencies=usd" | \
    jq ".\"${COIN}\".usd")

if [ $? -ne 0 ]
then
    echo "Unable to get coin price. Exiting..." >&2
    exit 6
fi

EXP_FIX_PRICE=$(sed -E 's/([+-]?[0-9.]+)[eE]\+?(-?)([0-9]+)/(\1*10^\2\3)/g' <<<"${COIN_PRICE}")
echo "EXP_FIX_PRICE: ${EXP_FIX_PRICE}" >&2
echo "DELEGATION_AMOUNT: ${DELEGATION_AMOUNT}" >&2
echo "DENOM: ${DENOM}" >&2

echo "${DELEGATION_AMOUNT} / ${DENOM} * $EXP_FIX_PRICE" | bc -l


