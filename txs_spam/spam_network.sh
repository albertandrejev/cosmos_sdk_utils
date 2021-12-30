#!/bin/bash

PATH_TO_SERVICE=${1}
KEY_PASSWORD=${2}
ACCOUNT=${3}
TO_ADDRESS=${4}
CHAIN_ID=${5}
MEMO=${6}
DENOM=${7}
SEND_AMOUNT=${8:-200}
FEE_AMOUNT=${9:-200}
NODE=${10:-"http://localhost:26657"}
PERIOD_VALUE=${11:-100}

ROUND=0
BROADCAST_MODE="async" 

SEQ=$(${PATH_TO_SERVICE} q account ${ACCOUNT} -o json | jq '.sequence | tonumber')

while :
do
    PERIOD=`expr ${ROUND} % ${PERIOD_VALUE}`

    echo "Running sequence: ${SEQ}"
    CURRENT_BLOCK=$(curl -s ${NODE}/abci_info | jq -r .result.response.last_block_height)

    if (( $PERIOD == 1 )); then
        BROADCAST_MODE="sync"
        echo "Sync broadcast mode"
    fi

    if (( $PERIOD == 4 )); then
        BROADCAST_MODE="async"
        echo "Async broadcast mode"
    fi

    TX_RESULT_RAW_LOG=$(echo $KEY_PASSWORD | $PATH_TO_SERVICE tx bank send $ACCOUNT $TO_ADDRESS \
        ${FEE_AMOUNT}${DENOM} \
        --fees ${FEE_AMOUNT}${DENOM} \
        --chain-id $CHAIN_ID \
        --output json \
        --note $MEMO \
        --broadcast-mode $BROADCAST_MODE \
        --sequence $SEQ \
        --timeout-height $(($CURRENT_BLOCK + 5)) -y | \
        jq '.raw_log')

    SEQ=$(($SEQ + 1))

    if [[ "$TX_RESULT_RAW_LOG" == *"incorrect account sequence"* ]]; then
        echo $TX_RESULT_RAW_LOG
        sleep 28
        SEQ=$(echo $TX_RESULT_RAW_LOG | sed 's/.* expected \([0-9]*\).*/\1/')
        echo $SEQ
    fi

    ROUND=`expr ${ROUND} + 1`
done


https://github.com/b-harvest/umee-autod/tree/tx_boom