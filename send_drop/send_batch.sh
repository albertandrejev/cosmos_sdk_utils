#!/bin/bash

BATCH_NUM=$1
PATH_TO_SERVICE=$2
KEYRING_PASSWORD=$3
KEY=$4
DENOM=$5
FEE=${6:-250}
GAS_LIMIT=${7:-2000000}
KEYRING_BACKEND=${8:-"os"}
NODE=${9:-"http://localhost:26657"}
NOTE=${10:-"Stakedrop from POSTHUMAN ꝏ DVS validator. Season 1. More info about supported networks: https:\/\/posthuman.digital"}

source ./utils.sh

get_chain_id $NODE
get_key_address $PATH_TO_SERVICE $KEY

get_holders_from_batch $BATCH_NUM

echo "Creating batch transaction..."
for HODLER_IDX in $( eval echo {0..$HODLERS_AMOUNT} )
do
    HODLER_DATA=$(echo "${HODLERS}" | jq ".[$HODLER_IDX]")

    HODLER_ADDRESS=$(echo "${HODLER_DATA}" | jq -r ".juno")
    AMOUNT=$(echo "${HODLER_DATA}" | jq -r ".amount")

    generate_exec_tx $KEY_ADDRESS $HODLER_ADDRESS $AMOUNT
done

echo "Broadcasting withdrawal transaction..."
sed "s/<!#TXS_BATCH>/${TXS_BATCH}/g" ./send-json.tmpl > ./stakedrop.json
sed -i "s/<!#DENOM>/${DENOM}/g" ./stakedrop.json
sed -i "s/<!#FEE>/${FEE}/g" ./stakedrop.json
sed -i "s/<!#GAS_LIMIT>/${GAS_LIMIT}/g" ./stakedrop.json
sed -i "s/<!#NOTE>/${NOTE} (Batch #${BATCH_NUM})/g" ./stakedrop.json

CMD="tx sign ./stakedrop.json 
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
