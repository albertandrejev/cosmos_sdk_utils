#!/bin/bash

PROVIDER_BIN=$1
CONSUMER_BIN=$2
PROVIDER_NODE=${3:-http://localhost:26657}
CONSUMER_NODE=${4:-http://localhost:26657}

source ./utils.sh

while true; do 
    CONSUMER_POWER=$(get_current_valset "$CONSUMER_BIN q tendermint-validator-set --node $CONSUMER_NODE")
    PROVIDER_POWER=$(get_current_valset "$PROVIDER_BIN q tendermint-validator-set --node $PROVIDER_NODE")

    DIFF_OUTPUT=$(diff <(echo "$CONSUMER_POWER") <(echo "$PROVIDER_POWER"))

    CUR_DATE=$(date "+%Y-%m-%d %H:%M:%S")

    if [ -n "$DIFF_OUTPUT" ]; then
        echo "$CUR_DATE | Provider and Consumer voting power are not equal!"
    else
        echo "$CUR_DATE | VALSETS ARE EQUAL!"
    fi

    sleep 5
done



NEUTRON_POWER=$(get_current_chain_data "../neutrond-linux-amd64 q tendermint-validator-set --node http://23.109.159.212:26657")
GAIA_POWER=$(get_current_chain_data "../gaiad-v9.1.0-linux-amd64 q tendermint-validator-set --node http://65.109.157.115:26657")

