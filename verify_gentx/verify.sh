#!/bin/bash

PATH_TO_SERVICE=$1
PATH_TO_GENTX=$2
DELEGATION=$3
DENOM=$4
COMMISSION_RATE=$5
COMMISSION_MAX_RATE=$6
COMMISSION_MAX_CHANGE_RATE=$7

GENTX=$(cat $PATH_TO_GENTX)
GENTX_COMMISSION_RATE=$(echo "$GENTX" | jq -r '.body.messages[0].commission.rate')
GENTX_COMMISSION_MAX_RATE=$(echo "$GENTX" | jq -r '.body.messages[0].commission.max_rate')
GENTX_COMMISSION_MAX_CHANGE_RATE=$(echo "$GENTX" | jq -r '.body.messages[0].commission.max_change_rate')
GENTX_DENOM=$(echo "$GENTX" | jq -r '.body.messages[0].value.denom')
GENTX_DELEGATION=$(echo "$GENTX" | jq -r '.body.messages[0].value.amount')

GENTX_MONIKER=$(echo "$GENTX" | jq -r '.body.messages[0].description.moniker')
GENTX_DELEGATOR_ADDRESS=$(echo "$GENTX" | jq -r '.body.messages[0].delegator_address')

echo "Moniker: $GENTX_MONIKER"
echo "Delegator address: $GENTX_DELEGATOR_ADDRESS"

ERROR=0

if (( $(echo "$GENTX_COMMISSION_RATE > $COMMISSION_RATE" | bc ) == 1 )); then
    echo "Commission rate in gentx is bigger to the one in the requirement"
    ERROR=1
fi

if (( $(echo "$GENTX_COMMISSION_MAX_RATE > $COMMISSION_MAX_RATE" | bc ) == 1 )); then
    echo "Commission max rate in gentx is bigger to the one in the requirement"
    ERROR=1
fi

if (( $(echo "$GENTX_COMMISSION_MAX_CHANGE_RATE > $COMMISSION_MAX_CHANGE_RATE" | bc ) == 1 )); then
    echo "Commission max change rate in gentx is bigger to the one in the requirement"
    ERROR=1
fi

if [[ "$GENTX_DENOM" != "$DENOM" ]]; then
    echo "Denom in gentx is different to the one in the requirement"
    ERROR=1
fi

if (( $(echo "$GENTX_DELEGATION > $DELEGATION" | bc ) == 1 )); then
    echo "Delegation in gentx is bigger to the one in the requirement"
    ERROR=1
fi

if (( $ERROR == 1 )); then
    echo "Exit due to errors above..."
    exit 1
fi

echo "Adding genesis account..."
$PATH_TO_SERVICE add-genesis-account $GENTX_DELEGATOR_ADDRESS ${DELEGATION}${DENOM}
$PATH_TO_SERVICE collect-gentxs
$PATH_TO_SERVICE tendermint unsafe-reset-all --home $HOME/.neutrond
$PATH_TO_SERVICE start
