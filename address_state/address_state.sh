#!/bin/bash

NAME=$1
ADDRESS=$2
DENOM=$3
DIVIDER=$4
WITH_REWARDS=$5
WITH_DELEGATIONS=$6
METRIC_FILE=$7
NODE_API_URL=${8:-"http://localhost:1317"}

cd $(dirname "$0")

network_up_and_synced () {
    local NODE=$1

    local NODE_STATUS_CODE=$(curl -m 5 -o /dev/null -s -w "%{http_code}\n" ${NODE}/syncing)

    if (( $NODE_STATUS_CODE != 200 )); then
        exit 1 # Node is not reacahble
    fi

    local SYNCING_STATUS=$(curl -s ${NODE}/syncing)
    local CHAIN_SYNC_STATE=$(echo $CHAIN_STATUS | jq '.syncing')
    if [[ "$CHAIN_SYNC_STATE" == "true" ]]
    then
        exit 2 # Node is catching up
    fi
}

network_up_and_synced $NODE_API_URL

ADDRESS_STATE=$(curl -m 30 -s ${NODE_API_URL}/bank/balances/${ADDRESS} | \
    /usr/bin/jq -r ".result[] | select(.denom | contains(\"${DENOM}\")).amount" | xargs)

if [ -z "$ADDRESS_STATE" ]
then
    ADDRESS_STATE=0
fi

if [ ${WITH_REWARDS,,} == "true" ]; then
    sleep 5
    REWARDS=$(curl -m 30 -s ${NODE_API_URL}/cosmos/distribution/v1beta1/delegators/${ADDRESS}/rewards | \
        /usr/bin/jq -r ".total[] | select(.denom | contains(\"${DENOM}\")).amount" | xargs)

    if [ ! -z "$REWARDS" ]
    then
        ADDRESS_STATE=$(echo "${ADDRESS_STATE} + ${REWARDS}" | bc)
    fi
fi

if [ ${WITH_DELEGATIONS,,} == "true" ]; then
    sleep 5
    DELEGATIONS=$(curl -m 30 -s ${NODE_API_URL}/cosmos/staking/v1beta1/delegations/${ADDRESS} | \
        /usr/bin/jq -r ".delegation_responses")

    TOTAL_DELEGATIONS=$(echo "${DELEGATIONS}" | jq 'length - 1')

    for DELEGATION_IDX in $( eval echo {0..$TOTAL_DELEGATIONS} )
    do
        DELEGATION_DATA=$(echo "${DELEGATIONS}" | jq ".[$DELEGATION_IDX]")
        AMOUNT=$(echo "${DELEGATION_DATA}" | jq -r ".balance.amount" | xargs)

        if [ ! -z "$AMOUNT" ]
        then
            ADDRESS_STATE=$(echo "${ADDRESS_STATE} + ${AMOUNT}" | bc)
        fi
    done
fi

ADDRESS_STATE=$(echo "${ADDRESS_STATE} / ${DIVIDER}" | bc)
echo "opentech_address_state{name=\"${NAME}\", address=\"${ADDRESS}\", denom=\"${DENOM}\"} $ADDRESS_STATE" >> $METRIC_FILE
