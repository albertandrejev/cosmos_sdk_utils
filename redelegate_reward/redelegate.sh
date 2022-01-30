#!/bin/bash

PATH_TO_SERVICE=$1
KEY_PASSWORD=$2
VALIDATOR_ADDRESS=$3
KEY=$4
DENOM=$5
FEE=${6:-250}
REMAINDER=${7:-1000000}
MIN_REWARD=${8:-10000000}
NODE=${9:-"http://localhost:26657"}

cd $(dirname "$0")

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

get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS --node $NODE -o json | \
    /usr/bin/jq ".rewards[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")

#DELEGATOR_REWARDS=0

BALANCE=$(${PATH_TO_SERVICE} q bank balances $DELEGATOR_ADDRESS --node $NODE -o json | \
    /usr/bin/jq ".balances[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")


TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$BALANCE-$REMAINDER-$FEE | bc | cut -f1 -d".")

if (( $TOTAL_REWARD > $MIN_REWARD )); then
    sed "s/<!#AMOUNT>/${TOTAL_REWARD}/g" redelegate-json.tmpl > redelegate.json
    sed -i "s/<!#VALIDATOR_ADDRESS>/${VALIDATOR_ADDRESS}/g" redelegate.json
    sed -i "s/<!#DELEGATOR_ADDRESS>/${DELEGATOR_ADDRESS}/g" redelegate.json
    sed -i "s/<!#DENOM>/${DENOM}/g" redelegate.json
    sed -i "s/<!#FEE>/${FEE}/g" redelegate.json


    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./redelegate.json \
        --from ${KEY} \
        --node $NODE \
        --chain-id ${CHAIN_ID} \
        --output-document ./signed.json

    ${PATH_TO_SERVICE} tx broadcast ./signed.json \
        --chain-id ${CHAIN_ID} \
        --node $NODE
else
    echo "Not enough rewards. Current balance: $BALANCE, rewards to payout: $TOTAL_REWARD, min. reward limit: $MIN_REWARD"
fi
