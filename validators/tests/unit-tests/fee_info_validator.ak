use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Spend, Transaction, placeholder,
}
use aiken/transaction/value.{add, from_asset, to_minted_value, zero}
use aiken_virtual_dex/placeholder.{
  mock_fee_ref_output, mock_fee_ref_token, mock_operation_key,
  mock_oracle_policy_id, mock_oracle_ref_input, mock_policy_id_5, mock_utxo_ref,
}
use aiken_virtual_dex/types.{FeeInfoDatum, RemoveFeeInfo, UpdateFee}
use aiken_virtual_dex/validators/fee_info_validator.{fee_info_validator_logic}

type UpdateFeeTestCase {
  is_mint_info_empty: Bool,
  is_operation_key_signed: Bool,
  is_datum_correct: Bool,
  is_output_value_clean: Bool,
}

fn base_update_fee_test_case() {
  UpdateFeeTestCase {
    is_mint_info_empty: True,
    is_operation_key_signed: True,
    is_datum_correct: True,
    is_output_value_clean: True,
  }
}

fn mock_update_fee_test_case(test_case: UpdateFeeTestCase) {
  let UpdateFeeTestCase {
    is_mint_info_empty,
    is_operation_key_signed,
    is_datum_correct,
    is_output_value_clean,
  } = test_case
  let policy_id = mock_fee_ref_token()
  let mint_value =
    if is_mint_info_empty {
      zero()
    } else {
      from_asset(policy_id, "123", 1)
    }
  let mint = to_minted_value(mint_value)
  let output_with_value =
    if is_output_value_clean {
      mock_fee_ref_output()
    } else {
      Output {
        ..mock_fee_ref_output(),
        value: mock_fee_ref_output().value |> add(policy_id, "123", 1),
      }
    }

  let inputs =
    [
      Input {
        output_reference: mock_utxo_ref(1),
        output: mock_fee_ref_output(),
      },
    ]

  let outputs =
    if is_datum_correct {
      [
        Output {
          ..output_with_value,
          datum: InlineDatum(
            FeeInfoDatum {
              long_token: ("", ""),
              short_token: (mock_policy_id_5(), "A potentially very long name"),
              min_fee: 1_000_000,
              percentage_fee: 1,
            },
          ),
        },
      ]
    } else {
      [output_with_value]
    }

  let extra_signatories =
    if is_operation_key_signed {
      [mock_operation_key()]
    } else {
      []
    }
  Transaction {
    ..placeholder(),
    inputs: inputs,
    outputs: outputs,
    extra_signatories: extra_signatories,
    reference_inputs: [mock_oracle_ref_input()],
    mint: mint,
  }
}

fn mock_datum() {
  FeeInfoDatum {
    long_token: ("", ""),
    short_token: (mock_policy_id_5(), "A potentially very long name"),
    min_fee: 0,
    percentage_fee: 0,
  }
}

test success_update_fee() {
  let redeemer = UpdateFee { new_min_fee: 1_000_000, new_percentage_fee: 1 }
  let output_reference = mock_utxo_ref(1)

  let tx = mock_update_fee_test_case(base_update_fee_test_case())
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  fee_info_validator_logic(mock_oracle_policy_id(), mock_datum(), redeemer, ctx)
}

test fail_update_fee_with_other_minting() {
  let redeemer = UpdateFee { new_min_fee: 1_000_000, new_percentage_fee: 1 }
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_update_fee_test_case(
      UpdateFeeTestCase {
        ..base_update_fee_test_case(),
        is_mint_info_empty: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

test fail_update_fee_without_operation_key_signed() {
  let redeemer = UpdateFee { new_min_fee: 1_000_000, new_percentage_fee: 1 }
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_update_fee_test_case(
      UpdateFeeTestCase {
        ..base_update_fee_test_case(),
        is_operation_key_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

test fail_update_fee_with_incorrect_datum() {
  let redeemer = UpdateFee { new_min_fee: 1_000_000, new_percentage_fee: 1 }
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_update_fee_test_case(
      UpdateFeeTestCase {
        ..base_update_fee_test_case(),
        is_datum_correct: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

test fail_update_fee_with_unclean_value() {
  let redeemer = UpdateFee { new_min_fee: 1_000_000, new_percentage_fee: 1 }
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_update_fee_test_case(
      UpdateFeeTestCase {
        ..base_update_fee_test_case(),
        is_output_value_clean: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

type RemoveFeeInfoTestCase {
  is_fee_ref_token_burnt: Bool,
  is_no_own_outputs: Bool,
  is_operating_key_signed: Bool,
}

fn base_remove_fee_info_test_case() {
  RemoveFeeInfoTestCase {
    is_fee_ref_token_burnt: True,
    is_no_own_outputs: True,
    is_operating_key_signed: True,
  }
}

fn mock_remove_fee_info_test_case(test_case: RemoveFeeInfoTestCase) {
  let RemoveFeeInfoTestCase {
    is_fee_ref_token_burnt,
    is_no_own_outputs,
    is_operating_key_signed,
  } = test_case
  let policy_id = mock_fee_ref_token()
  let mint_value =
    if is_fee_ref_token_burnt {
      from_asset(policy_id, "", -1)
    } else {
      zero()
    }
  let mint = to_minted_value(mint_value)

  let inputs =
    [
      Input {
        output_reference: mock_utxo_ref(1),
        output: mock_fee_ref_output(),
      },
    ]

  let outputs =
    if is_no_own_outputs {
      []
    } else {
      [mock_fee_ref_output()]
    }

  let extra_signatories =
    if is_operating_key_signed {
      [mock_operation_key()]
    } else {
      []
    }
  Transaction {
    ..placeholder(),
    inputs: inputs,
    outputs: outputs,
    extra_signatories: extra_signatories,
    reference_inputs: [mock_oracle_ref_input()],
    mint: mint,
  }
}

test success_remove_fee_info() {
  let redeemer = RemoveFeeInfo
  let output_reference = mock_utxo_ref(1)

  let tx = mock_remove_fee_info_test_case(base_remove_fee_info_test_case())
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  fee_info_validator_logic(mock_oracle_policy_id(), mock_datum(), redeemer, ctx)
}

test fail_remove_fee_info_with_other_minting() {
  let redeemer = RemoveFeeInfo
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_remove_fee_info_test_case(
      RemoveFeeInfoTestCase {
        ..base_remove_fee_info_test_case(),
        is_fee_ref_token_burnt: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

test fail_remove_fee_info_with_own_outputs() {
  let redeemer = RemoveFeeInfo
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_remove_fee_info_test_case(
      RemoveFeeInfoTestCase {
        ..base_remove_fee_info_test_case(),
        is_no_own_outputs: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}

test fail_remove_fee_info_without_operation_key_signed() {
  let redeemer = RemoveFeeInfo
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_remove_fee_info_test_case(
      RemoveFeeInfoTestCase {
        ..base_remove_fee_info_test_case(),
        is_operating_key_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !fee_info_validator_logic(
    mock_oracle_policy_id(),
    mock_datum(),
    redeemer,
    ctx,
  )
}
