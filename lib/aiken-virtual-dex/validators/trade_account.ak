use aiken/transaction.{InlineDatum, ScriptContext, Spend, find_input}
use aiken/transaction/value.{PolicyId}
use aiken_virtual_dex/common.{
  all_key_signed, key_signed, only_input_datum_with, only_minted_token,
  outputs_at_with, valid_after, valid_before,
}
use aiken_virtual_dex/types.{
  EmergencyIncidentInitiation, InitiateEmergencyIncident, OracleDatum,
  TradeAccountDatum, TradeAccountRedeemer, TradeEmergencyAction,
  TradeEmergencyDatum, TradeNormalAction,
}
use aiken_virtual_dex/utils.{get_emergency_token_name}

pub fn trade_account_logic(
  oracle_nft: PolicyId,
  owner: ByteArray,
  emergency_token: PolicyId,
  _datum: TradeAccountDatum,
  redeemer: TradeAccountRedeemer,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  when redeemer is {
    TradeNormalAction -> {
      expect Spend(_) = purpose
      expect OracleDatum { operation_key, .. }: OracleDatum =
        only_input_datum_with(transaction.reference_inputs, oracle_nft, "")
      all_key_signed(transaction.extra_signatories, [owner, operation_key])
    }
    TradeEmergencyAction { withdraw_output } -> {
      expect Spend(_) = purpose
      expect Some(input) = find_input(transaction.inputs, withdraw_output)
      expect InlineDatum(raw_datum) = input.output.datum
      expect casted_datum: TradeAccountDatum = raw_datum
      when casted_datum is {
        TradeEmergencyDatum { valid_since, minter } -> {
          let is_minted_info_correct = minter == owner
          let is_owner_signed = key_signed(transaction.extra_signatories, owner)
          let is_time_valid =
            valid_after(transaction.validity_range, valid_since)
          let is_emergency_token_burnt =
            only_minted_token(
              transaction.mint,
              emergency_token,
              get_emergency_token_name(input.output.address),
              -1,
            )
          is_minted_info_correct && is_owner_signed && is_time_valid && is_emergency_token_burnt
        }
        _ -> False
      }
    }
    InitiateEmergencyIncident { initiate_before } -> {
      expect Spend(own_utxo) = purpose
      expect Some(input) = find_input(transaction.inputs, own_utxo)
      let current_address = input.output.address
      expect [own_output] =
        outputs_at_with(
          transaction.outputs,
          current_address,
          emergency_token,
          get_emergency_token_name(current_address),
        )

      let is_owner_signed = key_signed(transaction.extra_signatories, owner)
      let is_emergency_token_minted =
        only_minted_token(
          transaction.mint,
          emergency_token,
          get_emergency_token_name(current_address),
          1,
        )
      let is_input_datum_correct =
        when input.output.datum is {
          InlineDatum(inline_datum) -> {
            expect EmergencyIncidentInitiation { owner: owner_address }: TradeAccountDatum =
              inline_datum
            owner_address == owner
          }
          _ -> False
        }
      let is_output_correct =
        when own_output.datum is {
          InlineDatum(inline_datum) -> {
            expect TradeEmergencyDatum { valid_since, minter }: TradeAccountDatum =
              inline_datum
            minter == owner && valid_since == initiate_before
          }
          _ -> False
        }
      let is_time_valid =
        valid_before(transaction.validity_range, initiate_before)
      is_owner_signed && is_emergency_token_minted && is_input_datum_correct && is_output_correct && is_time_valid
    }
  }
}
