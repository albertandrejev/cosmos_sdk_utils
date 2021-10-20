#!/bin/bash

PATH_TO_SERVICE=$1
VALIDATOR_ADDRESS=$2

JAILED_STATUS=$(${PATH_TO_SERVICE} q staking validators --limit 1000 --output json | \
    /usr/bin/jq ".validators[] | select(.operator_address | contains(\"${VALIDATOR_ADDRESS}\")).jailed")

JAILED_STATUS_NUM=0

if [ $JAILED_STATUS == "true" ]; then
    JAILED_STATUS_NUM=1
fi

echo "cosmos_jailed_status $JAILED_STATUS_NUM" > /var/lib/node_exporter/cosmos_jailed_status.prom

