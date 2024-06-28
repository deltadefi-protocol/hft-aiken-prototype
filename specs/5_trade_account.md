# Specification - TradeAccount

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`
- `owner`: The pub key has of account owner
- `emergency_token`: The policy id of the emergency token

## Datum

1. TradeNormalDatum

   - Stating that the UTxO is ready for normal app operation, including placing orders, taking orders and authorized withdrawal

2. TradeEmergencyDatum {valid_since, minter}

   - Stating that the UTxO is attached with an emergency token, ready for user withdrawal without passing through application logic

3. EmergencyIncidentInitiation {owner}

   - Stating that the UTxO is ready to be the authorization input for minting the emergency token.

## User Action

1. Normal operation - Redeemer `TradeNormalAction`

   - Reference to oracle utxo
   - Signed by operation key & owner

2. Emergency operation - Redeemer `TradeEmergencyAction {withdraw_output}`

   - Signed by owner
   - owner == minter in datum (to make sure the emergency token burnt with correct token name)
   - Validity range is after `valid_since`
   - `EmergencyToken` with correct token name of hash of current address is burnt in current transaction

3. Emergency operation - Redeemer `InitiateEmergencyIncident {initiate_before}`

   - Signed by owner
   - Emergency token is minted
   - Input UTxO is with datum of `EmergencyIncidentInitiation {owner}`
   - Transaction has a validity interval before `initiate_before`
   - Output UTxO back to current address with `TradeEmergencyAction` Datum attached inline and with `EmergencyToken`
   - `initiate_before` == `valid_since` in output datum
