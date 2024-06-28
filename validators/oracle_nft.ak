use aiken/transaction.{OutputReference, ScriptContext}
use aiken_virtual_dex/types.{MintPolarity}
use aiken_virtual_dex/validators/oracle_nft.{oracle_nft_logic}

validator(utxo_ref: OutputReference) {
  fn oracle_nft(redeemer: MintPolarity, context: ScriptContext) -> Bool {
    oracle_nft_logic(utxo_ref, redeemer, context)
  }
}
