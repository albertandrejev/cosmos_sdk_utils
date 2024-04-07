#!/bin/bash

VALOPER=$1
NODE_API_URL=${2:-"http://localhost:1317"}
LIMIT=${3:-"1000"}

LATEST_BLOCK=$(curl -s ${NODE_API_URL}/cosmos/base/tendermint/v1beta1/blocks/latest)

LATEST_BLOCK_HEIGHT=$(echo "$LATEST_BLOCK" | jq -r '.block.header.height')

WORK_DIR="compensation_at_${LATEST_BLOCK_HEIGHT}"

mkdir ${WORK_DIR} -p


PAGE=0
while true
do
    echo "Processing page $((PAGE+1))..."
    QUERY="${NODE_API_URL}/cosmos/staking/v1beta1/validators/${VALOPER}/delegations?pagination.limit=${LIMIT}"
    if [ ! -z "$NEXT_PAGE" ]
    then
        OFFSET=$(echo "${PAGE} * ${LIMIT}" | bc)
        QUERY="${QUERY}&pagination.offset=${OFFSET}"
    fi
    echo "${QUERY}"
    DELEGATIONS=$(curl -m 30 --insecure -s ${QUERY})
    PAGINATION=$(echo "${DELEGATIONS}" | jq -r '.pagination // ""')

    echo $DELEGATIONS > ${WORK_DIR}/delegators_page_${PAGE}_${VALOPER}.json

    if [ -z "$PAGINATION" ]
    then
        echo "Retrying to query page #${PAGE} again."
    else
        NEXT_PAGE=$(echo "${DELEGATIONS}" | jq -r '.pagination.next_key')
        echo "Next page: ${NEXT_PAGE}"
        if [ -z "$NEXT_PAGE" ] || [ "$NEXT_PAGE" == "null" ]
        then
            break
        fi

        PAGE=$(echo $((++PAGE)))        
    fi

    sleep 5
done

source ./generate_list.sh ${WORK_DIR}

echo "Done!"
