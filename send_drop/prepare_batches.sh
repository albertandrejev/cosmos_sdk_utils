#!/bin/bash

BATCH_SIZE=${1:-100}

source ./utils.sh

echo "Collecting data..."

get_holders_data

get_total_batches $HODLERS_AMOUNT $BATCH_SIZE

echo "Total batches: ${TOTAL_BATCHES}"
echo "Prepare batches..."
for BATCH_NUM in $( eval echo {0..$TOTAL_BATCHES} )
do
    echo "Creating batch #${BATCH_NUM}..."
    STARTING_IDX=$(echo "${BATCH_NUM} * ${BATCH_SIZE}" | bc)
    END_IDX=$(echo "${STARTING_IDX} + ${BATCH_SIZE}" | bc)
    if [ "$END_IDX" -gt "$HODLERS_AMOUNT" ]; then
        END_IDX=$(echo "${HODLERS_AMOUNT} + 1" | bc)
    fi

    BATCH_DATA=$(echo "${HODLERS}" | jq -r ".[${STARTING_IDX}:${END_IDX}]")

    echo "${BATCH_DATA}" > "${WORKING_DIR}/drop_batch_${BATCH_NUM}.json"
done
