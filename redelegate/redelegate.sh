#!/bin/bash

PATH_TO_SERVICE=$1
KEY_PASSWORD=$2
DELEGATOR_ADDRESS=$3
VALIDATOR_ADDRESS=$4
ACCOUNT=$5
CHAIN_ID=$6
DENOM=$7
FEE=${8:-250}
REMAINDER=${9:-1000000}
MIN_REWARD=${10:-10000000}
NODE=${11:-"http://localhost:26657"}

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS --node $NODE -o json | \
    /usr/bin/jq '.rewards[0].amount' | tr -d '"')

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDRESS --node $NODE -o json | \
    /usr/bin/jq '.commission[0].amount' | tr -d '"')

BALANCE=$(${PATH_TO_SERVICE} q bank balances $DELEGATOR_ADDRESS --node $NODE -o json | jq ".balances[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")

echo $BALANCE

TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$VALIDATOR_COMMISSION+$BALANCE-$REMAINDER | bc | cut -f1 -d".")

echo $TOTAL_REWARD

if (( $TOTAL_REWARD > $MIN_REWARD )); then
    sed "s/<!#AMOUNT>/${TOTAL_REWARD}/g" redelegate-json.tmpl > redelegate.json
    sed -i "s/<!#VALIDATOR_ADDRESS>/${VALIDATOR_ADDRESS}/g" redelegate.json
    sed -i "s/<!#DELEGATOR_ADDRESS>/${DELEGATOR_ADDRESS}/g" redelegate.json
    sed -i "s/<!#DENOM>/${DENOM}/g" redelegate.json
    sed -i "s/<!#FEE>/${FEE}/g" redelegate.json


    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./redelegate.json \
        --from ${ACCOUNT} \
        --node $NODE \
        --chain-id ${CHAIN_ID} \
        --output-document ./signed.json

    ${PATH_TO_SERVICE} tx broadcast ./signed.json \
        --chain-id ${CHAIN_ID} \
        --node $NODE
fi
