#!/bin/bash

PATH_TO_SERVICE=$1
DELEGATOR_ADDRESS=$2
VALIDATOR_ADDRESS=$3

DELEGATOR_REWARDS=$(${PATH_TO_SERVICE} q distribution rewards $DELEGATOR_ADDRESS $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.rewards[0].amount' | tr -d '"')

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDRESS -o json | \
    /usr/bin/jq '.commission[0].amount' | tr -d '"')

TOTAL_REWARD=$(echo $DELEGATOR_REWARDS+$VALIDATOR_COMMISSION| bc | cut -f1 -d".")


echo "cosmos_total_reward $TOTAL_REWARD" > /var/lib/node_exporter/cosmos_total_reward.prom