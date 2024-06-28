# Specification - FeeRefToken

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`

## User Action

1. Mint - Redeemer RMint

   - Only 1 `FeeToken` is minted with empty token name
   - 1 output to `FeeInfoValidator`, value length of 2
   - The inline datum attached with the output is in format of `FeeInfoDatum` (geq 0 fee)
   - Signed by both operation key

2. Burn - Redeemer RBurn

   - The current policy id only has negative minting value in transaction body.
