#!/bin/bash

PATH_TO_SERVICE=$1
DELEGATOR_ADDRESS=$2
VALIDATOR_ADDRESS=$3
DENOM=$4

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq ".rewards[] | select(.denom | contains(\"$DENOM\")).amount | tonumber") #"

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq ".commission[] | select(.denom | contains(\"$DENOM\")).amount | tonumber") #"

TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$VALIDATOR_COMMISSION| bc | cut -f1 -d".")


echo "cosmos_total_reward $TOTAL_REWARD" > /var/lib/node_exporter/cosmos_total_reward.prom