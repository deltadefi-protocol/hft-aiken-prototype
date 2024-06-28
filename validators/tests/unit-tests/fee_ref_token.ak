use aiken/transaction.{
  InlineDatum, Mint, Output, ScriptContext, Transaction, placeholder,
}
use aiken/transaction/value.{add, from_asset, to_minted_value}
use aiken_virtual_dex/placeholder.{
  mock_fee_ref_output, mock_fee_ref_token, mock_operation_key,
  mock_oracle_policy_id, mock_oracle_ref_input, mock_policy_id_2,
  mock_policy_id_5,
}
use aiken_virtual_dex/types.{FeeInfoDatum, RBurn, RMint}
use aiken_virtual_dex/validators/fee_ref_token.{fee_ref_token_logic}

type TestCase {
  is_fee_token_minted: Bool,
  is_fee_token_output_clean: Bool,
  is_fee_datum_correct: Bool,
  is_operating_key_signed: Bool,
}

fn base_test_case() {
  TestCase {
    is_fee_token_minted: True,
    is_fee_token_output_clean: True,
    is_fee_datum_correct: True,
    is_operating_key_signed: True,
  }
}

fn mock_test_case(test_case: TestCase) {
  let TestCase {
    is_fee_token_minted,
    is_fee_token_output_clean,
    is_fee_datum_correct,
    is_operating_key_signed,
  } = test_case
  let policy_id = mock_fee_ref_token()
  let mint_value =
    if is_fee_token_minted {
      from_asset(policy_id, "", 1)
    } else {
      from_asset(policy_id, "123", 1)
    }
  let mint = to_minted_value(mint_value)
  let output_with_value =
    if is_fee_token_output_clean {
      mock_fee_ref_output()
    } else {
      Output {
        ..mock_fee_ref_output(),
        value: mock_fee_ref_output().value |> add(policy_id, "123", 1),
      }
    }

  let outputs =
    if is_fee_datum_correct {
      [output_with_value]
    } else {
      [
        Output {
          ..output_with_value,
          datum: InlineDatum(
            FeeInfoDatum {
              long_token: ("", ""),
              short_token: (mock_policy_id_5(), "A potentially very long name"),
              min_fee: -1,
              percentage_fee: -1,
            },
          ),
        },
      ]
    }

  let extra_signatories =
    if is_operating_key_signed {
      [mock_operation_key()]
    } else {
      []
    }
  Transaction {
    ..placeholder(),
    mint: mint,
    outputs: outputs,
    extra_signatories: extra_signatories,
    reference_inputs: [mock_oracle_ref_input()],
  }
}

test success_mint() {
  let redeemer = RMint
  let policy_id = mock_fee_ref_token()

  let tx = mock_test_case(base_test_case())
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_mint_without_fee_token_minted() {
  let redeemer = RMint
  let policy_id = mock_fee_ref_token()

  let tx =
    mock_test_case(TestCase { ..base_test_case(), is_fee_token_minted: False })
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_mint_with_unclean_fee_token_output() {
  let redeemer = RMint
  let policy_id = mock_fee_ref_token()

  let tx =
    mock_test_case(
      TestCase { ..base_test_case(), is_fee_token_output_clean: False },
    )
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_mint_without_correct_datum() {
  let redeemer = RMint
  let policy_id = mock_fee_ref_token()

  let tx =
    mock_test_case(TestCase { ..base_test_case(), is_fee_datum_correct: False })
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_mint_without_operation_key_signed() {
  let redeemer = RMint
  let policy_id = mock_fee_ref_token()

  let tx =
    mock_test_case(
      TestCase { ..base_test_case(), is_operating_key_signed: False },
    )
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test success_burn() {
  let redeemer = RBurn
  let policy_id = mock_fee_ref_token()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "", -1)),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test success_burn_with_other_minting() {
  let redeemer = RBurn
  let policy_id = mock_fee_ref_token()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(
        from_asset(policy_id, "", -1) |> add(mock_policy_id_2(), "", 1),
      ),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_burn_with_mint() {
  let redeemer = RBurn
  let policy_id = mock_fee_ref_token()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(from_asset(policy_id, "", 1)),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}

test fail_burn_with_mix() {
  let redeemer = RBurn
  let policy_id = mock_fee_ref_token()

  let tx =
    Transaction {
      ..placeholder(),
      mint: to_minted_value(
        from_asset(policy_id, "", -1) |> add(policy_id, "1", 1),
      ),
    }
  let ctx = ScriptContext { purpose: Mint(policy_id), transaction: tx }
  !fee_ref_token_logic(mock_oracle_policy_id(), redeemer, ctx)
}
