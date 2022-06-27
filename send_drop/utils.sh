#!/bin/bash

WORKING_DIR="./data"

get_chain_id () {
    local NODE=$1

    CHAIN_ID=$(curl -s ${NODE}/status | jq -r '.result.node_info.network')
}

get_key_address () {
    local PATH_TO_SERVICE=$1
    local KEY=$2

    KEY_ADDRESS=$(echo $KEYRING_PASSWORD | ${PATH_TO_SERVICE} keys show ${KEY} -a)
}

get_holders_data () {
    HODLERS=$(cat ${WORKING_DIR}/holders.json)
    HODLERS_AMOUNT=$(cat ${WORKING_DIR}/holders.json | jq 'length - 1')
}

get_total_batches () {
    local HODLERS_AMOUNT=$1
    local BATCH_SIZE=$2

    TOTAL_BATCHES=$(echo "((${HODLERS_AMOUNT} / ${BATCH_SIZE}) + ( ${HODLERS_AMOUNT} % ${BATCH_SIZE} > 0 )) - 1" | bc) 
}

get_holders_from_batch () {
    local BATCH_NUM=$1

    HODLERS=$(cat ${WORKING_DIR}/drop_batch_${BATCH_NUM}.json)
    HODLERS_AMOUNT=$(cat ${WORKING_DIR}/drop_batch_${BATCH_NUM}.json | jq 'length - 1') 
}

generate_exec_tx () {
    local FROM_ADDRESS=$1
    local TO_ADDRESS=$2
    local AMOUNT=$3

    local EXEC_TX=$(cat ./exec-contract-json.tmpl | sed "s/<!#FROM_ADDRESS>/${FROM_ADDRESS}/g")
    local EXEC_TX=$(echo $EXEC_TX | sed "s/<!#TO_ADDRESS>/${TO_ADDRESS}/g")
    local EXEC_TX=$(echo $EXEC_TX | sed "s/<!#AMOUNT>/${AMOUNT}/g")  

    if [ -z "$TXS_BATCH" ]
    then
        TXS_BATCH="$EXEC_TX"
    else
        TXS_BATCH=${TXS_BATCH},${EXEC_TX}
    fi    
}

execute_command () {
    local CMD_PARAMS=$1

    local CMD="$PATH_TO_SERVICE $CMD_PARAMS --output json"

    if [ "$KEYRING_BACKEND" != "test" ]; then
        local CMD="echo \"$KEYRING_PASSWORD\" | $CMD"
    fi

    FUNC_RETURN=$CMD
}
