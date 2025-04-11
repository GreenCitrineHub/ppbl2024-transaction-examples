#!/bin/bash

# ================================================================
# Script: mint-nft-with-image.sh
# Purpose: This script mints a new NFT on the Cardano blockchain.
# Usage:   ./mint-nft-with-image.sh <receiver_addr> <name> <imageUrl> <description>
# Example: ./mint-nft-with-image.sh addr_test1q... lesson2032 https://gimbalabs.com/g.png "Example NFT"
# =================================================================

# Load utility functions from utils.sh
# This script should contain helper functions such as `get_address_biggest_lovelace`
. utils.sh

# =================================================================
# Read Input Arguments
# =================================================================
receiver_addr=$1  # The wallet address that will receive the minted NFT
name=$2           # The name of the NFT token
imageUrl=$3       # URL of the image associated with the NFT
description=$4    # Description of the NFT
quantity=1        # Default quantity to mint (1 NFT)

# =================================================================
# Set Up Sender Wallet (Modify these as needed)
# =================================================================
# The sender wallet is the one that will mint the NFT.
# Make sure you have enough ADA in this wallet to cover fees. Please replace with your own address and signing key.
sender=addr_test1qqyvanljnlyg9u0geayhffr69qsukndrn6t28kuu6hvkj765rgk7yt8w8q46q9pfd8u4xy2gwsssf6v5l7z294hr07yq2y2wud
sender_key=payment.skey  # The signing key for the sender's wallet

# Optional: Instead of hardcoding, you can store these in an `env.sh` file.
# Create `env.sh` with the following content:
#   export sender=<your_address>
#   export sender_key=<path_to_signing_key>
# Then uncomment the line below to load these variables dynamically.
# . env.sh

# =================================================================
# Generate Policy Keys and Script
# =================================================================
# Each NFT needs a unique policy ID. We generate a new one based on $name.

# Generate verification and signing keys for the minting policy.
cardano-cli address key-gen \
  --verification-key-file mint-$name.vkey \
  --signing-key-file mint-$name.skey

# Extract the key hash from the verification key (used in the minting script).
cardano-cli address key-hash \
  --payment-verification-key-file mint-$name.vkey \
  --out-file mint-$name.pkh

# Define file paths for keys and scripts
mint_signing_key_file_path=mint-$name.skey
mint_script_file_path=mint-nft-token-$name.script

# Create a simple minting policy script.
# This policy allows minting only when signed with the key we generated above.
echo "{
  \"type\": \"sig\",
  \"keyHash\": \"$(cat mint-$name.pkh)\"
}" > $mint_script_file_path

# =================================================================
# Generate Policy ID
# =================================================================
# The policy ID is derived from the minting script.
cardano-cli conway transaction policyid \
  --script-file $mint_script_file_path > $name.cs

policy_id=$(cat $name.cs)  # Store the generated policy ID

# =================================================================
# Create NFT Metadata
# =================================================================
# This script calls `write-nft-metadata.sh` to generate the metadata JSON.
# The metadata includes:
#   - Policy ID
#   - Token name
#   - Image URL
#   - Description
./write-nft-metadata.sh $policy_id $name $imageUrl $description

# =================================================================
# Select UTXO for the Transaction
# =================================================================
# Use a helper function to find the UTXO with the most Lovelace in the sender's wallet.
tx_in=$(get_address_biggest_lovelace ${sender})

# =================================================================
# Convert Token Name to Hex
# =================================================================
# Cardano NFTs require token names in hexadecimal format.
token_hex=$(printf '%s' "$name" | xxd -p)

# Debugging Output
echo "Minting NFT: $name"
echo "Token Hex: $token_hex"
echo "Policy ID: $policy_id"
echo "Transaction Input: $tx_in"

# =================================================================
# Build the Minting Transaction
# =================================================================
cardano-cli conway transaction build \
  --testnet-magic 1 \  # Use testnet (modify if using mainnet)
  --tx-in $tx_in \  # The UTXO used as input
  --tx-out "$receiver_addr+1500000 + $quantity $policy_id.$token_hex" \  # Send NFT to receiver
  --mint "$quantity $policy_id.$token_hex" \  # Define minted asset
  --mint-script-file $mint_script_file_path \  # Reference the minting script
  --metadata-json-file metadata-$name.json \  # Attach metadata file
  --change-address $sender \  # Send any leftover ADA back to sender
  --required-signer $mint_signing_key_file_path \  # Signing key required for minting
  --out-file mint-nft.draft  # Output unsigned transaction draft

# =================================================================
# Sign the Transaction
# =================================================================
cardano-cli conway transaction sign \
  --signing-key-file $mint_signing_key_file_path \  # Policy signing key
  --signing-key-file $sender_key \  # Sender wallet signing key
  --testnet-magic 1 \  # Specify testnet
  --tx-body-file mint-nft.draft \  # Reference unsigned transaction
  --out-file mint-nft.signed  # Output signed transaction

# =================================================================
# Submit the Transaction
# =================================================================
cardano-cli conway transaction submit \
  --tx-file mint-nft.signed \
  --testnet-magic 1  # Send transaction to testnet

echo "NFT Minted Successfully!"
