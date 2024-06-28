use aiken/list
use aiken/transaction.{Input, ScriptContext, Spend, Transaction, placeholder}
use aiken/transaction/value.{from_asset, to_minted_value}
use aiken_virtual_dex/placeholder.{
  mock_operation_key, mock_oracle_datum, mock_oracle_output, mock_policy_id,
  mock_stop_key, mock_utxo_ref, mock_vkey_hex_2, mock_vkey_hex_3,
}
use aiken_virtual_dex/types.{OracleDatum, RotateKey, StopApp}
use aiken_virtual_dex/validators/oracle_validator.{oracle_validator_logic}

type RotateTestCase {
  is_old_stop_key_signed: Bool,
  is_new_stop_key_signed: Bool,
  is_datum_updated: Bool,
}

fn base_rotate_test_case() {
  RotateTestCase {
    is_old_stop_key_signed: True,
    is_new_stop_key_signed: True,
    is_datum_updated: True,
  }
}

fn mock_rotate_test_case(test_case: RotateTestCase) {
  let RotateTestCase {
    is_old_stop_key_signed,
    is_new_stop_key_signed,
    is_datum_updated,
  } = test_case
  let input_utxo = mock_utxo_ref(0)
  let new_stop_key = mock_vkey_hex_3()

  let extra_signatories =
    []
      |> list.concat(
           if is_old_stop_key_signed {
             [mock_stop_key()]
           } else {
             []
           },
         )
      |> list.concat(
           if is_new_stop_key_signed {
             [new_stop_key]
           } else {
             []
           },
         )
  let new_datum =
    if is_datum_updated {
      OracleDatum {
        ..mock_oracle_datum(),
        operation_key: mock_stop_key(),
        stop_key: new_stop_key,
      }
    } else {
      mock_oracle_datum()
    }

  let input =
    Input {
      output_reference: input_utxo,
      output: mock_oracle_output(mock_oracle_datum()),
    }
  let output = mock_oracle_output(new_datum)
  Transaction {
    ..placeholder(),
    inputs: [input],
    outputs: [output],
    extra_signatories: extra_signatories,
  }
}

test success_rotate_key() {
  let redeemer =
    RotateKey {
      new_operation_key: mock_stop_key(),
      new_stop_key: mock_vkey_hex_3(),
    }
  let input_utxo = mock_utxo_ref(0)

  let tx = mock_rotate_test_case(base_rotate_test_case())
  let ctx = ScriptContext { purpose: Spend(input_utxo), transaction: tx }

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}

test fail_rotate_key_without_old_stop_signature() {
  let redeemer =
    RotateKey {
      new_operation_key: mock_stop_key(),
      new_stop_key: mock_vkey_hex_3(),
    }
  let input_utxo = mock_utxo_ref(0)

  let tx =
    mock_rotate_test_case(
      RotateTestCase {
        ..base_rotate_test_case(),
        is_old_stop_key_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(input_utxo), transaction: tx }

  !oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}

test fail_rotate_key_without_new_stop_signature() {
  let redeemer =
    RotateKey {
      new_operation_key: mock_stop_key(),
      new_stop_key: mock_vkey_hex_3(),
    }
  let input_utxo = mock_utxo_ref(0)

  let tx =
    mock_rotate_test_case(
      RotateTestCase {
        ..base_rotate_test_case(),
        is_new_stop_key_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(input_utxo), transaction: tx }

  !oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}

// test fail_

test success_stop_app() {
  let redeemer = StopApp
  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(mock_policy_id(), "", -1)),
      extra_signatories: [mock_vkey_hex_2()],
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}

test fail_stop_app_without_stop_key() {
  let redeemer = StopApp
  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(mock_policy_id(), "", -1)),
      extra_signatories: [mock_operation_key()],
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  !oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}

test success_stop_app_without_oracle_nft_burnt() {
  let redeemer = StopApp
  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(mock_policy_id(), "not oracle nft", -1)),
      extra_signatories: [mock_stop_key()],
    }
  let ctx = ScriptContext { purpose: Spend(mock_utxo_ref(0)), transaction: tx }

  !oracle_validator_logic(mock_oracle_datum(), redeemer, ctx)
}
