#!/bin/bash

PATH_TO_SERVICE=$1
KEY_PASSWORD=$2
VALIDATOR_ADDRESS=$3
KEY=$4
DENOM=$5
FEE=${6:-250}
REMAINDER=${7:-1000000}
MIN_REWARD=${8:-1000000}
NODE=${9:-"http://localhost:26657"}

cd $(dirname "$0")

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

get_chain_id () {
    local NODE=$1

    CHAIN_ID=$(curl -s ${NODE}/status | jq -r '.result.node_info.network')
}

get_key_address () {
    local PATH_TO_SERVICE=$1
    local KEY=$2

    DELEGATOR_ADDRESS=$(echo $KEY_PASSWORD | ${PATH_TO_SERVICE} keys show ${KEY} -a)
}

echo "Starting new redelegation for ${DELEGATOR_ADDRESS}: "`date`" ========================="

network_up_and_synced $NODE
get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

ENGAGEMENT_ADDRESS=$(${PATH_TO_SERVICE} q poe contract-address ENGAGEMENT -o json | jq -r '.address' )

ENGAGEMENT_REWARD=$(${PATH_TO_SERVICE} q wasm contract-state smart ${ENGAGEMENT_ADDRESS} \
    "{\"withdrawable_rewards\": {\"owner\": \"${VALIDATOR_ADDRESS}\"}}" -o json | \
    /usr/bin/jq -r '.data.rewards.amount' )

VALIDATOR_REWARD=$(${PATH_TO_SERVICE} q poe validator-reward $VALIDATOR_ADDRESS --node $NODE --distribution)

BALANCE=$(${PATH_TO_SERVICE} q bank balances $DELEGATOR_ADDRESS --node $NODE -o json | \
    /usr/bin/jq -r ".balances[] | select(.denom | contains(\"$DENOM\")).amount")
echo $BALANCE

TOTAL_REWARD=$(echo $VALIDATOR_REWARD+$BALANCE+$ENGAGEMENT_REWARD-$REMAINDER | bc | cut -f1 -d".")

echo "'${ENGAGEMENT_REWARD}' '${VALIDATOR_REWARD}' '${BALANCE}' '${TOTAL_REWARD}'"

if (( $TOTAL_REWARD > $MIN_REWARD )); then

    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx wasm execute \
        $(${PATH_TO_SERVICE} q poe contract-address DISTRIBUTION -o json |jq -r '.address') '{"withdraw_rewards":{}}'  \
        --from ${KEY} \
        --fees ${FEE}${DENOM} \
        --node $NODE \
        --chain-id ${CHAIN_ID} \
        -y

    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx wasm execute \
        ${ENGAGEMENT_ADDRESS} '{"withdraw_rewards":{}}'  \
        --from ${KEY} \
        --fees ${FEE}${DENOM} \
        --node $NODE \
        --chain-id ${CHAIN_ID} \
        -y

    echo "waiting 60 seconds..."
    sleep 60

    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx poe self-delegate ${TOTAL_REWARD}${DENOM} 0${DENOM} \
        --from ${KEY} \
        --fees ${FEE}${DENOM} \
        -y
fi
