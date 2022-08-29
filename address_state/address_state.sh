#!/bin/bash

NAME=$1
ADDRESS=$2
ALIAS=$3
DENOM=$4
DIVIDER=$5
GET_BALANCE=$6
GET_REWARDS=$7
GET_DELEGATIONS=$8
METRIC_FILE=$9
NODE_API_URL=${10:-"http://localhost:1317"}

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

TOTAL=0

if [ ${GET_BALANCE,,} == "true" ]; then
    BALANCE=$(curl -m 30 -s ${NODE_API_URL}/cosmos/bank/v1beta1/balances/${ADDRESS} | \
        /usr/bin/jq -r '.balances')

    TOTAL_BALANCES=$(echo "${BALANCE}" | jq 'length' )
    if [ $TOTAL_BALANCES -gt 0 ]
    then
        ADDRESS_STATE=$(echo "${BALANCE}" | \
            /usr/bin/jq -r ".[] | select(.denom | contains(\"${DENOM}\")).amount" | xargs)
    elif [ $TOTAL_BALANCES -eq 0 ]
    then
        ADDRESS_STATE=0
    else
        exit 3 # Balance is not available
    fi

    if [ ! -z "$ADDRESS_STATE" ]
    then
        TOTAL=$(echo "${TOTAL} + ${ADDRESS_STATE}" | bc)
    fi
fi

if [ ${GET_REWARDS,,} == "true" ]; then
    sleep 5
    REWARDS=$(curl -m 30 -s ${NODE_API_URL}/cosmos/distribution/v1beta1/delegators/${ADDRESS}/rewards | \
        /usr/bin/jq -r ".total[] | select(.denom | contains(\"${DENOM}\")).amount" | xargs)

    if [ ! -z "$REWARDS" ]
    then
        TOTAL=$(echo "${TOTAL} + ${REWARDS}" | bc)
    fi
fi

if [ ${GET_DELEGATIONS,,} == "true" ]; then
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
            TOTAL=$(echo "${TOTAL} + ${AMOUNT}" | bc)
        fi
    done
fi

if [ ! -z "$TOTAL" ]
then
    TOTAL=$(echo "${TOTAL} / ${DIVIDER}" | bc)
    echo "opentech_address_state{name=\"${NAME}\", address=\"${ADDRESS}\", denom=\"${DENOM}\", alias=\"${ALIAS}\"} $TOTAL" >> $METRIC_FILE
fi
