# Specification - ChangeAccount

## Parameter

- `owner`: The pub key has of account owner
- `trade_account_address`: The address of the owner's trade account

## Datum

1. ChangeAccountDatum

   - Stating that the UTxO is ready for normal app operation, including placing orders, taking orders and authorized withdrawal

## User Action

1. Owner withdraws the amount from change address - Redeemer `OwnerWithdraw`

   - Signed by address owner

2. Core logic of auto refill without user action - Redeemer `AppRefill`

   - Value send to both change account and trade account is greater than input value from change account

3. Bypassing check if any other redeemer is with the core logic - Redeemer `MassRefill { refill_output }`

   - The output provided by redeemer is with correct redeemer of `AppRefill`
