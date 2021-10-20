#!/bin/bash

PATH_TO_SERVICE=$1
DELEGATOR_ADDRESS=$2
VALIDATOR_ADDRESS=$3
KEY_PASSWORD=$4

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.rewards[0].amount' | tr -d '"')

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.commission[0].amount' | tr -d '"')

TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$VALIDATOR_COMMISSION| bc | cut -f1 -d".")

sed "s/<!#AMOUNT>/${TOTAL_REWARD}/g" redelegate-json.tmpl > redelegate.json
sed -i "s/<!#VALIDATOR_ADDRESS>/${VALIDATOR_ADDRESS}/g" redelegate.json
sed -i "s/<!#DELEGATOR_ADDRESS>/${DELEGATOR_ADDRESS}/g" redelegate.json


echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./redelegate.json \
    --from opentech \
    --node http://localhost:26657 \
    --chain-id neuron-1 \
    --output-document ./signed.json

${PATH_TO_SERVICE} tx broadcast ./signed.json \
    --chain-id neuron-1 \
    --node http://localhost:26657
