#!/bin/bash

CONSUMER_BIN=$1
CONSUMER_NODE=${2:-http://localhost:26657}

source ./utils.sh

CURRENT_POWER=$(get_current_valset "$CONSUMER_BIN q tendermint-validator-set --node $CONSUMER_NODE")

while true; do 
    NEW_POWER=$(get_current_valset "$CONSUMER_BIN q tendermint-validator-set --node $CONSUMER_NODE")

    DIFF_OUTPUT=$(diff <(echo "$CURRENT_POWER") <(echo "$NEW_POWER"))

    CUR_DATE=$(date "+%Y-%m-%d %H:%M:%S")

    if [ -n "$DIFF_OUTPUT" ]; then
        echo "$CUR_DATE | VALSET UPDATE RECEIVED..."
        CURRENT_POWER="$NEW_POWER"
    else
        echo "$CUR_DATE | Waiting for valset update..."
    fi

    sleep 2
done
