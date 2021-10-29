#!/bin/bash

#NODE=$1

PATH_TO_SERVICE=${1}
KEY_PASSWORD=${2}
ACCOUNT=${3}
TO_ADDRESS=${4}
FEE_DENOM=${5}
FEE_AMOUNT=${6:=200}
NODE=${7:="http://localhost:26657"}

TOTAL_MESSAGES=$(cat txs.json | jq '.body.messages | length')

ROUND=0
BROADCAST_MODE="async" 

curl localhost:26657/unsafe_flush_mempool

SEQ=$(${PATH_TO_SERVICE} q account ${ACCOUNT} -o json | jq '.sequence | tonumber')
ACCOUNT_NUM=$(${PATH_TO_SERVICE} q account ${ACCOUNT} -o json | jq '.account_number | tonumber')

echo "Account num: $ACCOUNT_NUM"


while :
do
    PERIOD=`expr ${ROUND} % 200` 
    echo "Round ${ROUND}/${PERIOD}, sending ${TOTAL_MESSAGES} tx messages..."
      
    MEMO="Spam tx #$ROUND"

    echo "Sequence: $SEQ"        

    if [[ "$TX_RESULT_RAW_LOG" == *"incorrect account sequence"* ]]; then
        SEQ=$(echo $TX_RESULT_RAW_LOG | sed 's/.* expected \([0-9]*\).*/\1/')
        echo $SEQ
        echo $TX_RESULT_RAW_LOG
    fi

    if (( $PERIOD == 1 )); then
        BROADCAST_MODE="sync"
        echo "Sync broadcast mode"
    fi

    if (( $PERIOD == 10 )); then
        BROADCAST_MODE="async"
        echo "Async broadcast mode"
    fi
    

    sed "s/<!#TX_MEMO>/${MEMO}/g" txs.json.tmpl > txs.json
    sed -i "s/<!#FROM_ADDRESS>/${ACCOUNT}/g" txs.json
    sed -i "s/<!#TO_ADDRESS>/${TO_ADDRESS}/g" txs.json
    sed -i "s/<!#FEE_DENOM>/${FEE_DENOM}/g" txs.json
    sed -i "s/<!#FEE_AMOUNT>/${FEE_AMOUNT}/g" txs.json


    echo ${KEY_PASSWORD} | ${PATH_TO_SERVICE} tx sign ./txs.json \
        --sequence $SEQ \
        --offline \
        --account-number $ACCOUNT_NUM \
        --from opentech \
        --node $NODE \
        --chain-id neuron-1 \
        --output-document ./signed.json

    TX_RESULT_RAW_LOG=$(${PATH_TO_SERVICE} tx broadcast ./signed.json \
        --chain-id neuron-1 \
        --sequence $SEQ \
        --output json \
	    --broadcast-mode ${BROADCAST_MODE} \
        --node $NODE | jq '.raw_log')

    
    if (( $PERIOD == 0 )); then
        echo "Pause to process transactions ..."
        sleep 52
        curl localhost:26657/unsafe_flush_mempool
        sleep 7
    fi

    
    SEQ=`expr ${SEQ} + 1`
    ROUND=`expr ${ROUND} + 1`
done

