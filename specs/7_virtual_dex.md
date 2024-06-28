# Specification - VirtualDex

## Parameter

- `oracle_nft`: The policy id of `OracleNFT`
- `fee_ref_token`: The policy id of `FeeRefToken`
- `emergency_token`: The policy id of the emergency token

## Datum

- `change_account_address`: The address of the change account number of the owner
- `trade_account_address`: The address of the trade account number of the owner
- `buy_token`: The `AssetClass` of token the order creator is looking for
- `sell_token`: The `AssetClass` of token the order creator is selling
- `price`: Order exchange in a rate of `price` \* `buy_token` = `lot_size`
- `lot_size`: Quantity of `sell token` in this order

## User Action

1. Core logic of taking orders - Redeemer `TakeOrder {order_taker}`

   - Reference to oracle utxo
   - Accumulate proceeds supposed send to order creators, check output value to them

2. Bypassing check if any other redeemer is with the core logic - Redeemer `MassTakeOrder { take_order_input }`

   - The input provided by redeemer comes from same address ad own input
   - The input provided by redeemer is with correct redeemer of `TakeOrder`

3. Cancelling order which is mistakenly listed onchain - Redeemer `CancelOrder`

   - Whole value spent to `TradeAccount` with correct owner in datum
   - signed by both `operating_key` and owner

4. Emergency operation - Redeemer `EmergencyCancel`

   - `EmergencyToken` with token name hashing `trade_account_address` burnt in current transaction
