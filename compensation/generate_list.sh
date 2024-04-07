#!/bin/bash

WORK_DIR=$1

shopt -s globstar

DELEGATORS_FILE=${WORK_DIR}/delegators.json

echo "[]" > ${DELEGATORS_FILE}

for FILE in ${WORK_DIR}/delegators_page_*.json
do
    if [[ ! -f "$FILE" ]]
    then
        continue
    fi

    echo "Processing ${FILE}..."

    ALL_DELEGATORS=$(jq -s ".[0] + .[1].delegation_responses" ${DELEGATORS_FILE} ${FILE})

    echo "${ALL_DELEGATORS}" > ${DELEGATORS_FILE}
done

