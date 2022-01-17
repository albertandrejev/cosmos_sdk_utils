#!/bin/bash

IDENTITY=$1
VOTE_ACCOUNT=$2
NODE=${3:-"http://localhost:8899"}

COMMISSIONS=$(curl -s -X POST -H "Content-Type: application/json" -d "[ \
        {\"jsonrpc\":\"2.0\", \"id\":\"identity\", \"method\":\"getBalance\", \"params\":[\"${IDENTITY}\"]}, \
        {\"jsonrpc\":\"2.0\", \"id\":\"vote\", \"method\":\"getBalance\", \"params\":[\"${VOTE_ACCOUNT}\"]} \
    ]" ${NODE})

VOTE_COMMISSION=$(echo "$COMMISSIONS" | jq '.[] | select(.id=="vote") | .result.value | tonumber') #'
IDENTITY_COMMISSION=$(echo "$COMMISSIONS" | jq '.[] | select(.id=="identity") | .result.value | tonumber')

echo "opentech_solana_collected_commission{address=\"vote\"} $VOTE_COMMISSION" > /var/lib/node_exporter/opentech_solana_collected_commission.prom
echo "opentech_solana_collected_commission{address=\"identity\"} $IDENTITY_COMMISSION" >> /var/lib/node_exporter/opentech_solana_collected_commission.prom

