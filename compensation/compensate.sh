#!/bin/bash

PATH_TO_SERVICE=$1
KEYRING_PASSWORD=$2
VALIDATOR_ADDRESS=$3
KEY=$4
HEIGHT=$5
COMPENSATION_RATE=$6
DENOM=$7
FEE=${8:-250}
KEYRING_BACKEND=${9:-"os"}
NOTE=${10:-"Compensation from POSTHUMAN ꝏ DVS validator. Thank you for using our services. More info about supported networks: https:\/\/posthuman.digital"}
NODE=${11:-"http://localhost:26657"}
LIMIT=${12:-"100000"}

source ./utils.sh

get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

echo "Collecting data..."

get_validator_delegators $PATH_TO_SERVICE $VALIDATOR_ADDRESS $HEIGHT $NODE $LIMIT

echo "Calculating compensations..."
TOTAL_COMPENSATION=0
for DELEGATOR_IDX in $( eval echo {0..$DELEGATORS_AMOUNT} )
do
    DELEGATION_DATA=$(echo "${DELEGATORS}" | jq ".[$DELEGATOR_IDX]")

    DELEGATOR_ADDRESS=$(echo "${DELEGATION_DATA}" | jq -r ".delegation.delegator_address")
    DELEGATION_AMOUNT=$(echo "${DELEGATION_DATA}" | jq ".balance | select(.denom | contains(\"$DENOM\")).amount" | tr -d '"')

    COMPENSATION_AMOUNT=$(echo "$DELEGATION_AMOUNT * $COMPENSATION_RATE" | bc -l | cut -f1 -d".") #"

    echo "COMPENSATION AMOUNT: $DELEGATOR_ADDRESS | $DELEGATION_AMOUNT | $COMPENSATION_RATE | $COMPENSATION_AMOUNT"

    TOTAL_COMPENSATION=$(echo "$TOTAL_COMPENSATION + $COMPENSATION_AMOUNT" | bc -l) #"
        
    generate_send_tx $DELEGATOR_ADDRESS $COMPENSATION_AMOUNT
done

echo "Total compensation amount: ${TOTAL_COMPENSATION} ${DENOM}"
echo "Delegators amount: ${DELEGATORS_AMOUNT}"

get_boolean_option "Do you want to send compensation?"
SEND_COMPENSATION=$?

if [ "$SEND_COMPENSATION" -eq "0" ]; then
    exit
fi

echo "Broadcasting withdrawal transaction..."
sed "s/<!#TXS_BATCH>/${TXS_BATCH}/g" ./send-json.tmpl > ./compensation.json
sed -i "s/<!#DENOM>/${DENOM}/g" ./compensation.json
sed -i "s/<!#FEE>/${FEE}/g" ./compensation.json
sed -i "s/<!#NOTE>/${NOTE}/g" ./compensation.json

CMD="tx sign ./compensation.json 
    --from $KEY 
    --node $NODE 
    --chain-id $CHAIN_ID 
    --keyring-backend $KEYRING_BACKEND 
    --output-document ./signed.json"

execute_command "$CMD"
SIGN_CMD=$FUNC_RETURN

eval $SIGN_CMD

$PATH_TO_SERVICE tx broadcast ./signed.json \
    --output json \
    --chain-id $CHAIN_ID \
    --node $NODE
