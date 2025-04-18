#!/bin/bash

. ../env.sh
. ../utils.sh

slot=$1
end=$(expr $slot + 1200)

reference_utxo=aadfe74b13cd0001d067d02467788e618106459f96bf53c96f3a2da03b0f1b72#0

sender_tx_in=$(get_address_biggest_lovelace ${sender})

validator_addr=$(cardano-cli address build --testnet-magic 1 --payment-script-file slt-2056.plutus)
validator_tx_in=$(get_address_biggest_lovelace ${validator_addr})

cardano-cli conway transaction build \
	--testnet-magic 1 \
	--tx-in $sender_tx_in \
	--tx-in-collateral $sender_tx_in \
	--tx-in $validator_tx_in \
	--spending-tx-in-reference $reference_utxo \
	--spending-plutus-script-v3 \
	--spending-reference-tx-in-inline-datum-present \
	--spending-reference-tx-in-redeemer-file Claim.json \
	--invalid-before $slot \
	--invalid-hereafter $end \
	--change-address $sender \
	--out-file unlock-tokens.draft

cardano-cli conway transaction sign \
	--signing-key-file $sender_key \
	--testnet-magic 1 \
	--tx-body-file unlock-tokens.draft \
	--out-file unlock-tokens.signed

cardano-cli conway transaction submit \
	--tx-file unlock-tokens.signed \
	--testnet-magic 1
