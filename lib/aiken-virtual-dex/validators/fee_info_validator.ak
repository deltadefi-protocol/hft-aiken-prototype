use aiken/transaction.{ScriptContext, Spend, Transaction}
use aiken/transaction/value.{PolicyId, from_asset, from_minted_value}
use aiken_virtual_dex/common.{
  inputs_at_with, key_signed, only_input_datum_with, output_inline_datum,
  outputs_at_with, value_length,
}
use aiken_virtual_dex/types.{
  FeeInfoDatum, FeeInfoRedeemer, OracleDatum, RemoveFeeInfo, UpdateFee,
}

pub fn fee_info_validator_logic(
  oracle_nft: PolicyId,
  _datum: FeeInfoDatum,
  redeemer: FeeInfoRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  let Transaction {
    inputs,
    outputs,
    reference_inputs,
    mint,
    extra_signatories,
    ..
  } = transaction
  expect OracleDatum { fee_ref_token, fee_info_address, operation_key, .. }: OracleDatum =
    only_input_datum_with(reference_inputs, oracle_nft, "")
  when purpose is {
    Spend(_) ->
      when redeemer is {
        UpdateFee { new_min_fee, new_percentage_fee } -> {
          expect [own_input] =
            inputs_at_with(inputs, fee_info_address, fee_ref_token, "")
          expect [own_output] =
            outputs_at_with(outputs, fee_info_address, fee_ref_token, "")
          expect input_datum: FeeInfoDatum =
            output_inline_datum(own_input.output)
          expect output_datum: FeeInfoDatum = output_inline_datum(own_output)
          let is_mint_info_empty = value_length(from_minted_value(mint)) == 0
          let is_operation_key_signed =
            key_signed(extra_signatories, operation_key)
          let is_datum_correct =
            output_datum == FeeInfoDatum {
              ..input_datum,
              min_fee: new_min_fee,
              percentage_fee: new_percentage_fee,
            }
          let is_output_value_clean = value_length(own_output.value) == 2
          is_mint_info_empty && is_operation_key_signed && is_datum_correct && is_output_value_clean
        }

        RemoveFeeInfo -> {
          let is_fee_ref_token_burnt =
            from_minted_value(mint) == from_asset(fee_ref_token, "", -1)
          let own_outputs =
            outputs_at_with(outputs, fee_info_address, fee_ref_token, "")
          let is_no_own_outputs = own_outputs == []
          let is_operating_key_signed =
            key_signed(extra_signatories, operation_key)
          is_fee_ref_token_burnt && is_no_own_outputs && is_operating_key_signed
        }
      }
    _ -> False
  }
}
