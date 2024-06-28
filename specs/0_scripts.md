# List of Smart Contracts

There are in total 7 scripts for the DeltaDeFi virtual dex to work. Below provide description and pointers to a more detailed specs.

1. OracleNFT - [specification](./1_oracle_nft.md)

   - The one time minting policy, minting the NFT to be reference token locking in `OracleValidator`. It is used for serving static app information.

2. OracleValidator - [specification](./2_oracle_validator.md)

   - The validator locking `OracleNFT`, for serving app static information while protecting information integrity.

3. FeeRefToken - [specification](./3_fee_ref_token.md)

   - The reference token sitting in `FeeInfoValidator`, serving fee information.

4. FeeInfoValidator - [specification](./4_fee_info_validator.md)

   - The validator locking `FeeRefToken`, for serving fee information while protecting information integrity.

5. TradeAccount - [specification](./5_trade_account.md)

   - The script to be compiled into different addresses according to account number, storing the UTxO ready for place order.

6. ChangeAccount - [specification](./6_change_account.md)

   - The script to be compiled into different addresses according to account number, storing the change UTxO after transaction.

7. VirtualDEX - [specification](./7_virtual_dex.md)

   - The script governing the transaction logic.

8. EmergencyToken - [specification](./emergency_token.md)

   - The minting policy for taking any withdrawal / cancel actions solely by users.

## Param Dependency Graph

1. First layer

   - 1.1 `EmergencyToken` (no param)
   - 1.2 `OracleNFT` (param: `utxo_ref`)

2. Second layer

   - 2.1 `FeeRefToken` (param: 1.2)
   - 2.2 `FeeInfoValidator` (param: 1.2)

3. Third layer

   - 3.1`TradeAccount` (param: `owner`, 1.1, 1.2, 2.1)
   - 3.2 `VirtualDEX` (param: 1.1, 1.2, 2.1)

4. Fourth layer
   - 4.1 `ChangeAccount` (param: `owner`, 1.2, 3.1)
