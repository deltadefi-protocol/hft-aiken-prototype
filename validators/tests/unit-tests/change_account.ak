use aiken/dict
use aiken/transaction.{ScriptContext, Spend, Transaction, placeholder}
use aiken_virtual_dex/common.{compare_output_reference}
use aiken_virtual_dex/placeholder.{
  mock_change_input, mock_operation_key, mock_trade_account_address,
  mock_trade_output, mock_user_vkey_hex, mock_utxo_ref,
}
use aiken_virtual_dex/types.{
  AppRefill, ChangeAccountDatum, MassRefill, OwnerWithdraw,
}
use aiken_virtual_dex/validators/change_account.{change_account_logic}

fn mock_withdraw_test_case(is_owner_signed: Bool) {
  let extra_signatories =
    [
      if is_owner_signed {
        mock_user_vkey_hex()
      } else {
        mock_operation_key()
      },
    ]
  Transaction { ..placeholder(), extra_signatories: extra_signatories }
}

test success_withdraw() {
  let output_reference = mock_utxo_ref(1)
  let datum = ChangeAccountDatum

  let redeemer = OwnerWithdraw
  let tx = mock_withdraw_test_case(True)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_withdraw_without_owner_signature() {
  let output_reference = mock_utxo_ref(1)
  let datum = ChangeAccountDatum

  let redeemer = OwnerWithdraw
  let tx = mock_withdraw_test_case(False)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}

fn mock_app_refill_test_case(is_value_sufficient: Bool) {
  let inputs =
    [
      mock_change_input(1, 100_000_000),
      mock_change_input(2, 200_000_000),
      mock_change_input(3, 300_000_000),
    ]
  let outputs =
    [
      mock_trade_output(300_000_000),
      mock_trade_output(
        if is_value_sufficient {
          300_000_000
        } else {
          299_999_999
        },
      ),
    ]
  Transaction { ..placeholder(), inputs: inputs, outputs: outputs }
}

test success_app_refill() {
  let output_reference = mock_utxo_ref(41)
  let datum = ChangeAccountDatum

  let redeemer = AppRefill
  let tx = mock_app_refill_test_case(True)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_app_refill_without_sufficient_value() {
  let output_reference = mock_utxo_ref(41)
  let datum = ChangeAccountDatum

  let redeemer = AppRefill
  let tx = mock_app_refill_test_case(False)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}

fn mock_mass_refill_test_case(is_app_refill_redeemer_provided: Bool) {
  let inputs =
    [
      mock_change_input(1, 100_000_000),
      mock_change_input(2, 200_000_000),
      mock_change_input(3, 300_000_000),
    ]
  let outputs =
    [mock_trade_output(300_000_000), mock_trade_output(300_000_000)]
  let red1: Data =
    if is_app_refill_redeemer_provided {
      AppRefill
    } else {
      MassRefill { refill_input: mock_utxo_ref(42) }
    }
  let redeemers =
    dict.new()
      |> dict.insert(Spend(mock_utxo_ref(41)), red1, compare_output_reference)
      |> dict.insert(
           Spend(mock_utxo_ref(42)),
           MassRefill { refill_input: mock_utxo_ref(41) },
           compare_output_reference,
         )
      |> dict.insert(
           Spend(mock_utxo_ref(43)),
           MassRefill { refill_input: mock_utxo_ref(41) },
           compare_output_reference,
         )
  Transaction {
    ..placeholder(),
    inputs: inputs,
    outputs: outputs,
    redeemers: redeemers,
  }
}

test success_mass_refill() {
  let output_reference = mock_utxo_ref(41)
  let datum = ChangeAccountDatum

  let redeemer = MassRefill { refill_input: output_reference }
  let tx = mock_mass_refill_test_case(True)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_mass_refill_without_app_refill_redeemer() {
  let output_reference = mock_utxo_ref(41)
  let datum = ChangeAccountDatum

  let redeemer = MassRefill { refill_input: output_reference }
  let tx = mock_mass_refill_test_case(True)
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  change_account_logic(
    mock_user_vkey_hex(),
    mock_trade_account_address(),
    datum,
    redeemer,
    ctx,
  )
}
