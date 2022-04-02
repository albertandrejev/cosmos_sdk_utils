#!/bin/bash

# Colors
RED='\033[31m'
NC='\033[0m' # No Color

get_chain_id () {
    local NODE=$1

    CHAIN_ID=$(curl -s ${NODE}/status | jq -r '.result.node_info.network')
}

get_key_address () {
    local PATH_TO_SERVICE=$1
    local KEY=$2

    OWNER_ADDRESS=$(echo $KEYRING_PASSWORD | ${PATH_TO_SERVICE} keys show ${KEY} -a)
}

get_validator_delegators () {
    local PATH_TO_SERVICE=$1
    local VALIDATOR_ADDRESS=$2
    local HEIGHT=$3
    local NODE=$4    
    local LIMIT=$5

    local VALIDATOR_DELEGATIONS=$(${PATH_TO_SERVICE} q staking delegations-to $VALIDATOR_ADDRESS --node $NODE --height $HEIGHT --limit $LIMIT -o json)

    local NEXT_PAGE=$(echo ${VALIDATOR_DELEGATIONS} | jq '.pagination.next_key')
    if [ "$NEXT_PAGE" != "null" ]; then
        echo "Please increase page limit. There is more pages in the output."
        exit
    fi

    DELEGATORS=$(echo "${VALIDATOR_DELEGATIONS}" | jq '.delegation_responses')
    DELEGATORS_AMOUNT=$(echo "${DELEGATORS}" | jq 'length - 1')
}

generate_send_tx () {
    local ADDRESS=$1
    local CASHBACK=$2

    local SEND_TX=$(cat ./send-tx-json.tmpl | sed "s/<!#FROM_ADDRESS>/${OWNER_ADDRESS}/g")
    local SEND_TX=$(echo $SEND_TX | sed "s/<!#TO_ADDRESS>/${ADDRESS}/g")
    local SEND_TX=$(echo $SEND_TX | sed "s/<!#DENOM>/${DENOM}/g")
    local SEND_TX=$(echo $SEND_TX | sed "s/<!#AMOUNT>/${CASHBACK}/g")  

    if [ -z "$TXS_BATCH" ]
    then
        TXS_BATCH="$SEND_TX"
    else
        TXS_BATCH=${TXS_BATCH},${SEND_TX}
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

get_boolean_option () {
    local TEXT=$1

    while :
    do
        read -p "$TEXT (y/n): "  BOOLEAN_CHAR_VALUE

        if [ "$BOOLEAN_CHAR_VALUE" = "y" ]; then
            return 1
        fi

        if [ "$BOOLEAN_CHAR_VALUE" = "n" ]; then
            return 0
        fi

        echo -e "${RED}ERROR!${NC} Please choose 'y' or 'n'."
    done
}
