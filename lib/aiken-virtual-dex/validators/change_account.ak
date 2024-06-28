use aiken/transaction.{ScriptContext, Spend, Transaction, find_input}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{merge}
use aiken_virtual_dex/common.{
  get_all_value_from, get_all_value_to, key_signed, redeemer_from, value_geq,
}
use aiken_virtual_dex/types.{
  AppRefill, ChangeAccountDatum, ChangeAccountRedeemer, MassRefill,
  OwnerWithdraw,
}

pub fn change_account_logic(
  owner: ByteArray,
  trade_account_address: Address,
  _datum: ChangeAccountDatum,
  redeemer: ChangeAccountRedeemer,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  let Transaction { extra_signatories, redeemers, inputs, outputs, .. } =
    transaction
  expect Spend(own_utxo) = purpose
  when redeemer is {
    OwnerWithdraw -> key_signed(extra_signatories, owner)
    AppRefill -> {
      expect Some(own_input) = find_input(inputs, own_utxo)
      let own_address = own_input.output.address
      let input_value = get_all_value_from(inputs, own_address)
      let change_output_value = get_all_value_to(outputs, own_address)
      let trade_output_value = get_all_value_to(outputs, trade_account_address)
      merge(change_output_value, trade_output_value) |> value_geq(input_value)
    }
    MassRefill { refill_input } -> {
      expect Some(own_input) = find_input(inputs, own_utxo)
      let own_address = own_input.output.address
      expect Some(raw_target_redeemer) =
        redeemer_from(redeemers, inputs, refill_input, own_address)
      expect target_redeemer: ChangeAccountRedeemer = raw_target_redeemer
      when target_redeemer is {
        AppRefill -> True
        _ -> False
      }
    }
  }
}
