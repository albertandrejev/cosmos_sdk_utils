#!/bin/bash
set -e
set -o pipefail


CONFIG_DIR=$1
PATH_TO_SERVICE=$2
VALIDATOR_ADDRESS=$3
REST_NODES_LIST_PATH=$4
MAX_BLOCKS_TO_CHECK={5:-90}

source $CONFIG_DIR/config.sh

source ./utils.sh

if [ -z "$REST_NODES_LIST_PATH" ]
then
    echo "No list of REST nodes was provided"
    exit 1
fi

for HEIGHT in 0..10
do
    REST_NODE=$(get_rest_url $REST_NODES_LIST_PATH)
    NETWORK_STATUS=$(network_up_and_synced $REST_NODE)
    if [ "$NETWORK_STATUS" == "$NETWORK_STATUS_OK" ]; then
        break
    fi
done

if [ -z "$REST_NODE" ]
then
    echo "No working REST nodes found"
    notify_no_working_rest $CONFIG_DIR
    exit 2
fi

VALIDATOR_DATA_FILE="$DATA_DIR/validator_$VALIDATOR_ADDRESS.json"

CURRENT_HEIGHT=$(curl $NODE/status -s | jq ".result.sync_info.latest_block_height | tonumber")

get_height_commission () {
    local HEIGHT=$1

    local COMMISSION=$($PATH_TO_SERVICE q distribution commission \
        $VALIDATOR_ADDRESS \
        -o json --node $NODE --height $HEIGHT | \
        /usr/bin/jq ".commission[] | select(.denom | contains(\"$DENOM\")).amount | tonumber")

    if [[ $COMMISSION =~ $NUMBER_RE ]] ; then
        HEIGHT_COMMISSION=${COMMISSION}        
    else
        HEIGHT_COMMISSION=0
    fi    
}

if [ ! -f "$VALIDATOR_DATA_FILE" ]; then
    save_delegator_data $VALIDATOR_DATA_FILE $CURRENT_HEIGHT
    exit
fi

get_last_height $VALIDATOR_DATA_FILE

get_height_commission $LAST_HEIGHT
PREV_COMMISSION=$HEIGHT_COMMISSION
TOTAL_VALIDATOR_COMMISSION=0

if (( $(echo "($CURRENT_HEIGHT - $LAST_HEIGHT) > $MAX_BLOCKS_TO_CHECK" | bc ) == 1 )); then
    LAST_HEIGHT=$(echo "$CURRENT_HEIGHT - $MAX_BLOCKS_TO_CHECK" | bc )
fi

for HEIGHT in $( eval echo {$LAST_HEIGHT..$CURRENT_HEIGHT} )
do
    get_height_commission $HEIGHT

    if (( $(echo "$HEIGHT_COMMISSION < $PREV_COMMISSION" | bc ) == 1 )); then
        PREV_COMMISSION=0
    fi

    TOTAL_VALIDATOR_COMMISSION=$(echo "$HEIGHT_COMMISSION - $PREV_COMMISSION + $TOTAL_VALIDATOR_COMMISSION" | bc -l)   
    PREV_COMMISSION=$HEIGHT_COMMISSION
done

echo `date +%T`" - Total commission for period: $TOTAL_VALIDATOR_COMMISSION. Last height: $CURRENT_HEIGHT"

save_delegator_data $VALIDATOR_DATA_FILE $CURRENT_HEIGHT
