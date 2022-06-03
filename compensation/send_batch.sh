#!/bin/bash

BATCH_NUM=$1
HEIGHT=$2
PATH_TO_SERVICE=$3
KEYRING_PASSWORD=$4
VALIDATOR_ADDRESS=$5
KEY=$6
DENOM=$7
FEE=${8:-250}
GAS_LIMIT=${9:-2000000}
KEYRING_BACKEND=${10:-"os"}
NODE=${11:-"http://localhost:26657"}
NOTE=${12:-"Compensation from POSTHUMAN ꝏ DVS validator. Thank you for using our services. More info about supported networks: https:\/\/posthuman.digital"}


source ./utils.sh

get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

get_delegators_from_batch $BATCH_NUM

echo "Creating batch transaction..."
for DELEGATOR_IDX in $( eval echo {0..$DELEGATORS_AMOUNT} )
do
    DELEGATION_DATA=$(echo "${DELEGATORS}" | jq ".[$DELEGATOR_IDX]")

    DELEGATOR_ADDRESS=$(echo "${DELEGATION_DATA}" | jq -r ".address")
    COMPENSATION_AMOUNT=$(echo "${DELEGATION_DATA}" | jq -r ".compensation")

    generate_send_tx $DELEGATOR_ADDRESS $COMPENSATION_AMOUNT
done

echo "Broadcasting withdrawal transaction..."
sed "s/<!#TXS_BATCH>/${TXS_BATCH}/g" ./send-json.tmpl > ./compensation.json
sed -i "s/<!#DENOM>/${DENOM}/g" ./compensation.json
sed -i "s/<!#FEE>/${FEE}/g" ./compensation.json
sed -i "s/<!#GAS_LIMIT>/${GAS_LIMIT}/g" ./compensation.json
sed -i "s/<!#NOTE>/${NOTE} (Batch #${BATCH_NUM})/g" ./compensation.json

CMD="tx sign ./compensation.json 
    --from $KEY 
    --node $NODE 
    --chain-id $CHAIN_ID 
    --keyring-backend $KEYRING_BACKEND 
    --output-document ./signed.json"

execute_command "$CMD"
SIGN_CMD=$FUNC_RETURN
echo $SIGN_CMD

#eval $SIGN_CMD

#$PATH_TO_SERVICE tx broadcast ./signed.json \
#    --output json \
#    --chain-id $CHAIN_ID \
#    --node $NODE
