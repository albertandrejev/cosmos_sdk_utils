#!/bin/bash

PATH_TO_SERVICE=${1}
KEY_PASSWORD=${0}

TOTAL_TXS=$(cat txs.json | jq '.body.messages | length')

SLEEP=6

ROUND=1

while :
do
    echo "Round ${ROUND}, sending ${TOTAL_TXS} txs..."
    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./txs.json \
	--from opentech \
	--node http://localhost:26657 \
	--chain-id neuron-1 \
	--output-document ./signed.json

    ${PATH_TO_SERVICE} tx broadcast ./signed.json \
	--chain-id neuron-1 \
	--node http://localhost:26657

    echo "Sleeping for ${SLEEP} seconds..."
    sleep ${SLEEP}
    ROUND=`expr ${ROUND} + 1`
done