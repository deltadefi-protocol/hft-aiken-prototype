use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId}
use aiken_virtual_dex/types.{FeeInfoDatum, FeeInfoRedeemer}
use aiken_virtual_dex/validators/fee_info_validator.{fee_info_validator_logic}

validator(oracle_nft: PolicyId) {
  fn fee_info_validator(
    datum: FeeInfoDatum,
    redeemer: FeeInfoRedeemer,
    context: ScriptContext,
  ) {
    fee_info_validator_logic(oracle_nft, datum, redeemer, context)
  }
}
