#!/bin/bash

PATH_TO_SERVICE=$1
KEYRING_PASSWORD=$2
KEY=$3
DENOM=$4
FEE=${5:-250}
GAS_LIMIT=${6:-2000000}
START_BATCH=${7:-0}
BATCH_SIZE=${8:-100}
KEYRING_BACKEND=${9:-"os"}
NODE=${10:-"http://localhost:26657"}
NOTE=${11:-"Stakedrop from POSTHUMAN ꝏ DVS validator. Season 1. More info about supported networks: https:\/\/posthuman.digital"}

source ./utils.sh

get_holders_data
get_total_batches $HODLERS_AMOUNT $BATCH_SIZE

echo "Processing batches..."
for BATCH_NUM in $( eval echo {$START_BATCH..$TOTAL_BATCHES} )
do
    echo "Batch #${BATCH_NUM} of ${TOTAL_BATCHES}..."
    ./send_batch.sh \
    $BATCH_NUM \
    $PATH_TO_SERVICE \
    $KEYRING_PASSWORD \
    $KEY \
    $DENOM \
    $FEE \
    $GAS_LIMIT \
    $KEYRING_BACKEND \
    $NODE \
    "$NOTE"
done
