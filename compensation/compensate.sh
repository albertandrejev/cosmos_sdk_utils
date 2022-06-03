#!/bin/bash

HEIGHT=$1
PATH_TO_SERVICE=$2
KEYRING_PASSWORD=$3
VALIDATOR_ADDRESS=$4
KEY=$5
DENOM=$6
FEE=${7:-250}
GAS_LIMIT=${8:-2000000}
BATCH_SIZE=${9:-100}
KEYRING_BACKEND=${10:-"os"}
NODE=${11:-"http://localhost:26657"}
NOTE=${12:-"Compensation from POSTHUMAN ꝏ DVS validator. Thank you for using our services. More info about supported networks: https:\/\/posthuman.digital"}
LIMIT=${13:-"100000"}

source ./utils.sh

get_validator_delegators_cached
get_total_batches $DELEGATORS_AMOUNT $BATCH_SIZE

echo "Processing batches..."
for BATCH_NUM in $( eval echo {0..$TOTAL_BATCHES} )
do
    echo "Batch #${BATCH_NUM} of ${TOTAL_BATCHES}..."
    ./send_batch.sh \
    $BATCH_NUM \
    $HEIGHT \
    $PATH_TO_SERVICE \
    $KEYRING_PASSWORD \
    $VALIDATOR_ADDRESS \
    $KEY \
    $DENOM \
    $FEE \
    $GAS_LIMIT \
    $KEYRING_BACKEND \
    $NODE \
    "$NOTE"

    echo "Sleeping for 60 seconds"
    sleep 60
done
