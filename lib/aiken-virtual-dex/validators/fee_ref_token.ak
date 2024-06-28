use aiken/transaction.{InlineDatum, Mint, ScriptContext, Transaction}
use aiken/transaction/value.{PolicyId}
use aiken_virtual_dex/common.{
  check_policy_only_burn, key_signed, only_input_datum_with, only_minted_token,
  outputs_at_with, value_length,
}
use aiken_virtual_dex/types.{
  FeeInfoDatum, MintPolarity, OracleDatum, RBurn, RMint,
}

pub fn fee_ref_token_logic(
  oracle_nft: PolicyId,
  redeemer: MintPolarity,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  when purpose is {
    Mint(current_policy) ->
      when redeemer is {
        RMint -> {
          let Transaction {
            mint,
            reference_inputs,
            extra_signatories,
            outputs,
            ..
          } = transaction
          expect OracleDatum {
            fee_ref_token,
            fee_info_address,
            operation_key,
            ..
          }: OracleDatum =
            only_input_datum_with(reference_inputs, oracle_nft, "")
          expect [output] =
            outputs_at_with(outputs, fee_info_address, fee_ref_token, "")
          expect InlineDatum(raw_datum) = output.datum
          expect FeeInfoDatum {
            long_token: _,
            short_token: _,
            min_fee,
            percentage_fee,
          }: FeeInfoDatum = raw_datum
          let is_fee_token_minted =
            only_minted_token(mint, fee_ref_token, "", 1)
          let is_fee_token_output_clean = value_length(output.value) == 2
          let is_fee_datum_format_correct = min_fee >= 0 && percentage_fee >= 0
          let is_operating_key_signed =
            key_signed(extra_signatories, operation_key)
          is_fee_token_minted && is_fee_token_output_clean && is_fee_datum_format_correct && is_operating_key_signed
        }
        RBurn -> check_policy_only_burn(transaction.mint, current_policy)
      }
    _ -> False
  }
}
