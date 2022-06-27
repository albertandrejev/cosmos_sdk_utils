# Cosmos SDK based network redelegation script

This script intended to be used to automatically redelegate fee and commission from validator.
In order to run it is good to use crontab job.

### Usage

In order to run you need to provide 5 mandatory and 2 optional parameters

```
./spam_network.sh \
    <Path to network service exectuable> \
    <Password for the used account key> \
    <Delegator wallet address> \
    <Validator `...valoper1` address> \
    <Account name> \
    <Denomination, for example `uatom`> \
    <Transaction fee. Default: 250> \
    <Remainder of the tokens on wallet address. Default: 1000000> \
    <Minumum reward amount to collect. Default: 10000000>    
    <RPC Node. Default: http://localhost:26657> 
```
