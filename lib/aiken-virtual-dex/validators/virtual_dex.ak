use aiken/bytearray
use aiken/dict.{Dict}
use aiken/list
use aiken/transaction.{
  Input, Output, ScriptContext, Spend, Transaction, find_input,
}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value.{PolicyId, Value, from_asset, merge}
use aiken_virtual_dex/common.{
  inputs_at, key_signed, only_input_datum_with, only_minted_token,
  output_inline_datum, outputs_at, redeemer_from, value_geq,
}
use aiken_virtual_dex/types.{
  CancelOrder, EmergencyCancel, MassTakeOrder, OracleDatum, TakeOrder,
  VirtualDexDatum, VirtualDexRedeemer,
}
use aiken_virtual_dex/utils.{get_emergency_token_name}

pub fn compare_script_address(x: Address, y: Address) -> Ordering {
  expect ScriptCredential(x_hash) = x.payment_credential
  expect ScriptCredential(y_hash) = y.payment_credential
  bytearray.compare(x_hash, y_hash)
}

pub fn accumulate_all_to_return_value(
  inputs: List<Input>,
  own_address: Address,
) -> Dict<Address, (Address, Value)> {
  list.foldr(
    inputs,
    dict.new(),
    fn(x: Input, acc: Dict<Address, (Address, Value)>) {
      let is_from_same_address = own_address == x.output.address
      when is_from_same_address is {
        True -> {
          expect VirtualDexDatum {
            trade_account_address,
            change_account_address,
            buy_token: (policy, name),
            price,
            lot_size,
            ..
          }: VirtualDexDatum = output_inline_datum(x.output)
          let current_item = dict.get(acc, trade_account_address)
          let to_return_value = from_asset(policy, name, price * lot_size)
          when current_item is {
            None ->
              dict.insert(
                acc,
                trade_account_address,
                (change_account_address, to_return_value),
                compare_script_address,
              )
            Some((change_account_address, value)) ->
              dict.insert(
                acc,
                trade_account_address,
                (change_account_address, merge(value, to_return_value)),
                compare_script_address,
              )
          }
        }
        False -> acc
      }
    },
  )
}

pub fn accumuate_all_payment_value(
  outputs: List<Output>,
) -> Dict<Address, (Address, Value)> {
  list.foldr(
    outputs,
    dict.new(),
    fn(x: Output, acc: Dict<Address, (Address, Value)>) {
      let this_address = x.address
      let current_item = dict.get(acc, this_address)
      when current_item is {
        None ->
          dict.insert(
            acc,
            this_address,
            (this_address, x.value),
            compare_script_address,
          )
        Some((change_account_address, value)) ->
          dict.insert(
            acc,
            this_address,
            (change_account_address, merge(value, x.value)),
            compare_script_address,
          )
      }
    },
  )
}

pub fn virtual_dex_logic(
  oracle_nft: PolicyId,
  _fee_ref_token: PolicyId,
  emergency_token: PolicyId,
  datum: VirtualDexDatum,
  redeemer: VirtualDexRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context

  when redeemer is {
    TakeOrder { .. } -> {
      let Transaction { reference_inputs, inputs, outputs, .. } = transaction
      expect OracleDatum { .. }: OracleDatum =
        only_input_datum_with(reference_inputs, oracle_nft, "")
      expect Spend(own_utxo) = purpose
      expect Some(own_input) = find_input(transaction.inputs, own_utxo)
      let own_address = own_input.output.address
      // - Accumulate proceeds supposed send to order creators, check output value to them
      // 1. Look throught all inputs ->
      //       if from same address -> get (trade_account_address, change_account_address, receive_value)
      // 2. Merge all results above with same trade_account_address
      // 3. Check each unique trade_account_address, if outputs to trade_account + change_account >= to_receive
      let payment_values = accumuate_all_payment_value(outputs)
      accumulate_all_to_return_value(inputs, own_address)
        |> dict.to_list()
        |> list.all(
             fn(payment_item) {
               let (trade_account_address, (_, to_receive_value)) = payment_item
               expect Some((_, received_value)) =
                 dict.get(payment_values, trade_account_address)
               value_geq(received_value, to_receive_value)
             },
           )
    }

    MassTakeOrder { take_order_input } -> {
      let Transaction { inputs, redeemers, .. } = transaction
      expect Spend(own_utxo) = purpose
      expect Some(own_input) = find_input(transaction.inputs, own_utxo)
      let own_address = own_input.output.address
      expect Some(raw_target_redeemer) =
        redeemer_from(redeemers, inputs, take_order_input, own_address)
      expect target_redeemer: VirtualDexRedeemer = raw_target_redeemer
      when target_redeemer is {
        TakeOrder -> True
        _ -> False
      }
    }
    CancelOrder -> {
      expect Spend(own_utxo) = purpose
      let Transaction {
        inputs,
        outputs,
        reference_inputs,
        extra_signatories,
        ..
      } = transaction
      let VirtualDexDatum { trade_account_address, .. } = datum
      expect Some(input) = find_input(transaction.inputs, own_utxo)
      expect [own_input] = inputs_at(inputs, input.output.address)
      expect [trade_output] = outputs_at(outputs, trade_account_address)
      expect OracleDatum { operation_key, .. }: OracleDatum =
        only_input_datum_with(reference_inputs, oracle_nft, "")
      let is_order_value_returned = own_input.output.value == trade_output.value
      let is_operation_key_signed = key_signed(extra_signatories, operation_key)
      is_order_value_returned && is_operation_key_signed
    }
    EmergencyCancel -> {
      let Transaction { mint, .. } = transaction
      let VirtualDexDatum { trade_account_address, .. } = datum
      let is_emergency_token_burnt =
        only_minted_token(
          mint,
          emergency_token,
          get_emergency_token_name(trade_account_address),
          -1,
        )
      is_emergency_token_burnt
    }
  }
}
