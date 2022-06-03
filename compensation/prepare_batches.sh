#!/bin/bash

HEIGHT=$1
COMPENSATION_RATE=$2
BATCH_SIZE=${3:-100}

source ./utils.sh

NUM_RE='^[0-9]+$'

echo "Collecting data..."

get_validator_delegators_cached

get_total_batches $DELEGATORS_AMOUNT $BATCH_SIZE

echo "Total batches: ${TOTAL_BATCHES}"
echo "Calculating compensations and prepare batches..."
TOTAL_COMPENSATION=0
for BATCH_NUM in $( eval echo {0..$TOTAL_BATCHES} )
do
    echo "Creating batch #${BATCH_NUM}..."
    BATCH_DATA="[]"
    STARTING_IDX=$(echo "${BATCH_NUM} * ${BATCH_SIZE}" | bc)
    END_IDX=$(echo "${STARTING_IDX} + ${BATCH_SIZE} - 1" | bc)
    if [ "$END_IDX" -ge "$DELEGATORS_AMOUNT" ]; then
        END_IDX=$(echo "${DELEGATORS_AMOUNT} - 1" | bc)
    fi

    echo "Processing records from ${STARTING_IDX} to ${END_IDX}..."
    for DELEGATOR_IDX in $( eval echo {$STARTING_IDX..$END_IDX} )
    do
        DELEGATION_DATA=$(echo "${DELEGATORS}" | jq ".[$DELEGATOR_IDX]")

        DELEGATOR_ADDRESS=$(echo "${DELEGATION_DATA}" | jq -r ".delegation.delegator_address")
        DELEGATION_AMOUNT=$(echo "${DELEGATION_DATA}" | jq ".balance | select(.denom | contains(\"$DENOM\")).amount" | tr -d '"') #'

        COMPENSATION_AMOUNT=$(echo "$DELEGATION_AMOUNT * $COMPENSATION_RATE" | bc -l | cut -f1 -d".") #'

        if [ ! -z "$COMPENSATION_AMOUNT" ] && [[ $COMPENSATION_AMOUNT =~ $NUM_RE ]] && [[ $COMPENSATION_AMOUNT > 0 ]]
        then
            echo "COMPENSATION AMOUNT: $DELEGATOR_ADDRESS | $DELEGATION_AMOUNT | $COMPENSATION_RATE | $COMPENSATION_AMOUNT"

            TOTAL_COMPENSATION=$(echo "$TOTAL_COMPENSATION + $COMPENSATION_AMOUNT" | bc -l) #"
                
            BATCH_DATA=$(echo "${BATCH_DATA}" | jq ". += [{\"address\": \"${DELEGATOR_ADDRESS}\", \"compensation\": ${COMPENSATION_AMOUNT}}]")
        fi
    done

    echo "${BATCH_DATA}" > "${WORKING_DIR}/compensation_batch_${BATCH_NUM}.json"
done

echo "Total compensation amount: ${TOTAL_COMPENSATION} ${DENOM}"
echo "Delegators amount: ${DELEGATORS_AMOUNT}"
