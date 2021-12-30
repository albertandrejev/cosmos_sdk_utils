#!/bin/bash

PATH_TO_SERVICE=$1
VALIDATOR_ADDR=$2
NETWORK=$3
DENOM=$4
NODE=${5:-"http://localhost:26657"}

VALIDATOR_COMMISSION=$(${PATH_TO_SERVICE} q distribution commission $VALIDATOR_ADDR --node ${NODE} -o json | \
    /usr/bin/jq ".commission[] | select(.denom | contains(\"${DENOM}\")).amount | tonumber")


#echo $VALIDATOR_COMMISSION
echo "opentech_cosmos_total_commission{network=\"${NETWORK}\"} $VALIDATOR_COMMISSION" > /var/lib/node_exporter/opentech_cosmos_total_commission.prom

