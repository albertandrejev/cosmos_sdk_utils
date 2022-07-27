#!/bin/bash

PATH_TO_SERVICE=$1
KEYRING_PASSWORD=$2
VALIDATOR_ADDRESS=$3
KEY=$4
DENOM=$5
FEE=${6:-250}
GAS_LIMIT=${7:-2000000}
BATCH_SIZE=${8:-100}
KEYRING_BACKEND=${9:-"os"}
NODE=${10:-"http://localhost:26657"}
NOTE=${11:-"Compensation from POSTHUMAN ꝏ DVS validator. Thank you for using our services. More info about supported networks: https:\/\/posthuman.digital"}

source ./utils.sh

get_validator_delegators_cached
get_total_batches $DELEGATORS_AMOUNT $BATCH_SIZE

echo "Processing batches..."
for BATCH_NUM in $( eval echo {0..$TOTAL_BATCHES} )
do
    echo "Batch #${BATCH_NUM} of ${TOTAL_BATCHES}..."
    ./send_batch.sh \
    $BATCH_NUM \
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
