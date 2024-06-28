use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId}
use aiken_virtual_dex/types.{MintPolarity}
use aiken_virtual_dex/validators/fee_ref_token.{fee_ref_token_logic}

validator(oracle_nft: PolicyId) {
  fn fee_ref_token(redeemer: MintPolarity, context: ScriptContext) -> Bool {
    fee_ref_token_logic(oracle_nft, redeemer, context)
  }
}
