#!/bin/bash
set -e
set -o pipefail

VALIDATOR_ADDRESS=$1
LAST_HEIGHT=$2
PREV_COMMISSION=$3
CONFIG_FILE=${4:-"./config.sh"}
DATA_DIR=${5:-"./data"}

mkdir -p $DATA_DIR
source $CONFIG_FILE

source ./utils.sh

CURRENT_HEIGHT=$(network_up_and_synced $NODE)

VALIDATOR_DATA_FILE="$DATA_DIR/$VALIDATOR_ADDRESS.json"

if [ ! -f "$VALIDATOR_DATA_FILE" ]; then
    HEIGHT_COMMISSION=$(get_height_commission $CURRENT_HEIGHT $DENOM)
    save_validator_data $VALIDATOR_DATA_FILE $CURRENT_HEIGHT $HEIGHT_COMMISSION
    exit
fi

TOTAL_VALIDATOR_COMMISSION=0

if (( $(echo "($CURRENT_HEIGHT - $LAST_HEIGHT) > $MAX_BLOCKS_TO_CHECK" | bc ) == 1 )); then
    LAST_HEIGHT=$(echo "$CURRENT_HEIGHT - $MAX_BLOCKS_TO_CHECK" | bc )
fi

for HEIGHT in $( eval echo {$LAST_HEIGHT..$CURRENT_HEIGHT} )
do
    HEIGHT_COMMISSION=$(get_height_commission $HEIGHT $DENOM)
    echo "Height: $HEIGHT" >&2
    echo "Commission: $HEIGHT_COMMISSION" >&2
    echo "Prev commission: $PREV_COMMISSION" >&2
    if [ "$HEIGHT_COMMISSION" != "$NO_COMMISSION_ERR" ] && ([ ! -v PREV_COMMISSION ] || [ -z "$PREV_COMMISSION" ] || [ "$PREV_COMMISSION" == "$NO_COMMISSION_ERR" ]); then
        echo "SETTING PREV COMMISSION" >&2
        PREV_COMMISSION=$HEIGHT_COMMISSION
    elif [ "$HEIGHT_COMMISSION" == "$NO_COMMISSION_ERR" ] ; then
        continue
    fi

    if (( $(echo "$HEIGHT_COMMISSION < $PREV_COMMISSION" | bc ) == 1 )); then
        PREV_COMMISSION=0
    fi

    TOTAL_VALIDATOR_COMMISSION=$(echo "$HEIGHT_COMMISSION - $PREV_COMMISSION + $TOTAL_VALIDATOR_COMMISSION" | bc -l)   
    PREV_COMMISSION=$HEIGHT_COMMISSION
done

echo `date +%T`" - Total commission for period: $TOTAL_VALIDATOR_COMMISSION. Last height: $CURRENT_HEIGHT, last known commission: $HEIGHT_COMMISSION"

save_validator_data $VALIDATOR_DATA_FILE $CURRENT_HEIGHT $HEIGHT_COMMISSION

