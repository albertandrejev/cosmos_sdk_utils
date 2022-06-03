#!/bin/bash

PATH_TO_SERVICE=$1
KEY_PASSWORD=$2
KEY=$3
TO_ADDRESS=$4
DENOM=$5
FEE=${6:-250}
REMAINDER=${7:-1000000}
MIN_REWARD=${8:-10000000}
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

network_up_and_synced $NODE
get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

echo "Send accumulated reward from ${DELEGATOR_ADDRESS} to ${TO_ADDRESS}: "`date`" ========================="

while :
do
    BALANCE=$(${PATH_TO_SERVICE} q bank balances $DELEGATOR_ADDRESS --node $NODE -o json | \
        /usr/bin/jq ".balances[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")


    TOTAL_REWARD=$(echo $BALANCE-$REMAINDER-$FEE | bc | cut -f1 -d".")

    if (( $TOTAL_REWARD > $MIN_REWARD )); then
        sed "s/<!#AMOUNT>/${TOTAL_REWARD}/g" send-json.tmpl > send.json
        sed -i "s/<!#DELEGATOR_ADDRESS>/${DELEGATOR_ADDRESS}/g" send.json
        sed -i "s/<!#TO_ADDRESS>/${TO_ADDRESS}/g" send.json
        sed -i "s/<!#DENOM>/${DENOM}/g" send.json
        sed -i "s/<!#FEE>/${FEE}/g" send.json


        echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./send.json \
            --from ${KEY} \
            --node $NODE \
            --chain-id ${CHAIN_ID} \
            --output-document ./signed.json

        ${PATH_TO_SERVICE} tx broadcast ./signed.json \
            --chain-id ${CHAIN_ID} \
            --node $NODE

        break
    fi

    echo "Sleeping 4 secs..."
    sleep 4
done

echo "Funds was rescued"
