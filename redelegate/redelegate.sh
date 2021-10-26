#!/bin/bash

PATH_TO_SERVICE=$1
DELEGATOR_ADDRESS=$2
VALIDATOR_ADDRESS=$3
FROM=$4
CHAIN_ID=$5
DENOM=$6
KEY_PASSWORD=$7

REMAINDER=1000000

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.rewards[0].amount' | tr -d '"')

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.commission[0].amount' | tr -d '"')

BALANCE=$(${PATH_TO_SERVICE} q bank balances $DELEGATOR_ADDRESS -o json | jq ".balances[0].amount | tonumber")

echo $BALANCE

TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$VALIDATOR_COMMISSION+$BALANCE-$REMAINDER | bc | cut -f1 -d".")

echo $TOTAL_REWARD

sed "s/<!#AMOUNT>/${TOTAL_REWARD}/g" redelegate-json.tmpl > redelegate.json
sed -i "s/<!#VALIDATOR_ADDRESS>/${VALIDATOR_ADDRESS}/g" redelegate.json
sed -i "s/<!#DELEGATOR_ADDRESS>/${DELEGATOR_ADDRESS}/g" redelegate.json
sed -i "s/<!#DENOM>/${DENOM}/g" redelegate.json


echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./redelegate.json \
    --from ${FROM} \
    --node http://localhost:26657 \
    --chain-id ${CHAIN_ID} \
    --output-document ./signed.json

${PATH_TO_SERVICE} tx broadcast ./signed.json \
    --chain-id ${CHAIN_ID} \
    --node http://localhost:26657
