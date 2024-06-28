use aiken/transaction.{Mint, ScriptContext, Transaction}
use aiken_virtual_dex/common.{
  check_policy_only_burn, inputs_at, key_signed, only_minted_token,
  output_inline_datum, outputs_at, valid_before,
}
use aiken_virtual_dex/types.{
  EBurn, EMint, EmergencyIncidentInitiation, EmergencyTokenMintingPolarity,
  TradeAccountDatum, TradeEmergencyDatum,
}
use aiken_virtual_dex/utils.{get_emergency_token_name}

pub fn emergency_token_logic(
  redeemer: EmergencyTokenMintingPolarity,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  expect Mint(current_policy) = purpose
  when redeemer is {
    EMint { current_timestamp, trade_account_address } -> {
      let Transaction {
        inputs,
        outputs,
        mint,
        extra_signatories,
        validity_range,
        ..
      } = transaction
      expect [initiation_input] = inputs_at(inputs, trade_account_address)
      expect EmergencyIncidentInitiation { owner }: TradeAccountDatum =
        output_inline_datum(initiation_input.output)
      expect [emergency_output] = outputs_at(outputs, trade_account_address)
      expect TradeEmergencyDatum { valid_since, minter }: TradeAccountDatum =
        output_inline_datum(emergency_output)
      let is_emergency_token_name_correct =
        only_minted_token(
          mint,
          current_policy,
          get_emergency_token_name(trade_account_address),
          1,
        )
      let is_datum_correct = owner == minter && valid_since == current_timestamp
      let is_owner_signed = key_signed(extra_signatories, owner)
      let is_time_valid = valid_before(validity_range, current_timestamp)
      is_owner_signed && is_emergency_token_name_correct && is_datum_correct && is_time_valid
    }
    EBurn -> check_policy_only_burn(transaction.mint, current_policy)
  }
}
