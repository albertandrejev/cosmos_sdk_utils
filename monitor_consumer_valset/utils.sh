#!/bin/bash


get_current_valset () {
    local CMD=$1
    local OUT_FILE=$2

    eval $CMD | grep voting_power
}