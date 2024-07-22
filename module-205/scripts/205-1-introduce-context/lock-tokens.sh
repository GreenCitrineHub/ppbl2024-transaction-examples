#!/bin/bash

. ../env.sh
. ../utils.sh

validator_addr=$(cardano-cli address build --testnet-magic 1 --payment-script-file introduce-context-aiken.plutus)

tx_in=$(get_address_biggest_lovelace ${sender})

cardano-cli transaction build \
--babbage-era \
--testnet-magic 1 \
--tx-in $tx_in \
--tx-out $validator_addr+7000000 \
--tx-out-inline-datum-value 321 \
--change-address $sender \
--out-file lock-tokens.draft

cardano-cli transaction sign \
--signing-key-file $sender_key \
--testnet-magic 1 \
--tx-body-file lock-tokens.draft \
--out-file lock-tokens.signed

cardano-cli transaction submit \
--tx-file lock-tokens.signed \
--testnet-magic 1