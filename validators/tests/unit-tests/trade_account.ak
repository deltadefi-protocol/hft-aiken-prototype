use aiken/transaction.{Input, ScriptContext, Spend, Transaction, placeholder}
use aiken/transaction/value.{from_asset, to_minted_value, zero}
use aiken_virtual_dex/placeholder.{
  mock_emergency_action_input, mock_emergency_action_output,
  mock_emergency_initiation_input, mock_emergency_initiation_output,
  mock_emergency_token, mock_interval, mock_operation_key, mock_oracle_policy_id,
  mock_oracle_ref_input, mock_trade_account_address, mock_trade_input,
  mock_user_vkey_hex, mock_utxo_ref,
}
use aiken_virtual_dex/types.{
  EmergencyIncidentInitiation, InitiateEmergencyIncident, TradeEmergencyAction,
  TradeEmergencyDatum, TradeNormalAction, TradeNormalDatum,
}
use aiken_virtual_dex/utils.{get_emergency_token_name}
use aiken_virtual_dex/validators/trade_account.{trade_account_logic}

type TradeTestCase {
  is_owner_signed: Bool,
  is_operation_key_signed: Bool,
}

fn base_trade_test_case() {
  TradeTestCase { is_owner_signed: True, is_operation_key_signed: True }
}

fn mock_trade_test_case(test_case: TradeTestCase) {
  let TradeTestCase { is_owner_signed, is_operation_key_signed } = test_case
  let extra_signatories =
    when (is_owner_signed, is_operation_key_signed) is {
      (True, True) ->
        [mock_user_vkey_hex(), mock_operation_key()]
      (True, False) ->
        [mock_user_vkey_hex()]
      (False, True) ->
        [mock_operation_key()]
      (False, False) ->
        []
    }
  Transaction {
    ..placeholder(),
    extra_signatories: extra_signatories,
    reference_inputs: [mock_oracle_ref_input()],
  }
}

test success_trade() {
  let redeemer = TradeNormalAction
  let output_reference = mock_utxo_ref(1)

  let tx = mock_trade_test_case(base_trade_test_case())
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    TradeNormalDatum,
    redeemer,
    ctx,
  )
}

test fail_trade_without_operation_key() {
  let redeemer = TradeNormalAction
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_trade_test_case(
      TradeTestCase { ..base_trade_test_case(), is_operation_key_signed: False },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    TradeNormalDatum,
    redeemer,
    ctx,
  )
}

test fail_trade_without_owner_key() {
  let redeemer = TradeNormalAction
  let output_reference = mock_utxo_ref(1)

  let tx =
    mock_trade_test_case(
      TradeTestCase { ..base_trade_test_case(), is_owner_signed: False },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    TradeNormalDatum,
    redeemer,
    ctx,
  )
}

type EmergencyActionTestCase {
  is_owner_signed: Bool,
  is_input_datum_correct: Bool,
  is_time_valid: Bool,
  is_emergency_token_burnt: Bool,
}

fn base_emergency_action_test_case() {
  EmergencyActionTestCase {
    is_owner_signed: True,
    is_input_datum_correct: True,
    is_time_valid: True,
    is_emergency_token_burnt: True,
  }
}

fn mock_emergency_action_test_case(test_case: EmergencyActionTestCase) {
  let EmergencyActionTestCase {
    is_owner_signed,
    is_input_datum_correct,
    is_time_valid,
    is_emergency_token_burnt,
  } = test_case

  let extra_signatories =
    when is_owner_signed is {
      True ->
        [mock_user_vkey_hex()]
      False ->
        []
    }
  let emergency_action_input =
    if is_input_datum_correct {
      mock_emergency_action_input(1, 100, mock_user_vkey_hex())
    } else {
      mock_emergency_action_input(1, 100, mock_operation_key())
    }
  let inputs =
    [mock_trade_input(1), mock_trade_input(2), emergency_action_input]
  let mint =
    to_minted_value(
      if is_emergency_token_burnt {
        from_asset(
          mock_emergency_token(),
          get_emergency_token_name(mock_trade_account_address()),
          -1,
        )
      } else {
        zero()
      },
    )
  let validity_range =
    mock_interval(
      Some(
        if is_time_valid {
          101
        } else {
          99
        },
      ),
      None,
    )
  Transaction {
    ..placeholder(),
    mint: mint,
    extra_signatories: extra_signatories,
    validity_range: validity_range,
    inputs: inputs,
  }
}

test success_emergency_withdraw() {
  let output_reference = mock_utxo_ref(31)
  let datum =
    TradeEmergencyDatum { valid_since: 100, minter: mock_user_vkey_hex() }

  let redeemer = TradeEmergencyAction { withdraw_output: output_reference }
  let tx = mock_emergency_action_test_case(base_emergency_action_test_case())
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_emergency_withdraw_without_owner_signature() {
  let output_reference = mock_utxo_ref(31)
  let datum =
    TradeEmergencyDatum { valid_since: 100, minter: mock_user_vkey_hex() }

  let redeemer = TradeEmergencyAction { withdraw_output: output_reference }
  let tx =
    mock_emergency_action_test_case(
      EmergencyActionTestCase {
        ..base_emergency_action_test_case(),
        is_owner_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_emergency_withdraw_with_invalid_time() {
  let output_reference = mock_utxo_ref(31)
  let datum =
    TradeEmergencyDatum { valid_since: 100, minter: mock_user_vkey_hex() }

  let redeemer = TradeEmergencyAction { withdraw_output: output_reference }
  let tx =
    mock_emergency_action_test_case(
      EmergencyActionTestCase {
        ..base_emergency_action_test_case(),
        is_time_valid: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_emergency_withdraw_without_emergency_token_burnt() {
  let output_reference = mock_utxo_ref(31)
  let datum =
    TradeEmergencyDatum { valid_since: 100, minter: mock_user_vkey_hex() }

  let redeemer = TradeEmergencyAction { withdraw_output: output_reference }
  let tx =
    mock_emergency_action_test_case(
      EmergencyActionTestCase {
        ..base_emergency_action_test_case(),
        is_emergency_token_burnt: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

type InitiateEmergencyTestCase {
  is_owner_signed: Bool,
  is_emergency_token_minted: Bool,
  is_input_datum_correct: Bool,
  is_output_correct: Bool,
  is_time_valid: Bool,
}

fn base_initiate_emergency_test_case() {
  InitiateEmergencyTestCase {
    is_owner_signed: True,
    is_emergency_token_minted: True,
    is_input_datum_correct: True,
    is_output_correct: True,
    is_time_valid: True,
  }
}

fn mock_initiate_emergency_test_case(test_case: InitiateEmergencyTestCase) {
  let InitiateEmergencyTestCase {
    is_owner_signed,
    is_emergency_token_minted,
    is_input_datum_correct,
    is_output_correct,
    is_time_valid,
  } = test_case

  let extra_signatories =
    when is_owner_signed is {
      True ->
        [mock_user_vkey_hex()]
      False ->
        []
    }

  let inputs =
    [
      if is_input_datum_correct {
        mock_emergency_initiation_input(1)
      } else {
        Input {
          output_reference: mock_utxo_ref(21),
          output: mock_emergency_initiation_output(mock_operation_key()),
        }
      },
    ]
  let outputs =
    if is_output_correct {
      [mock_emergency_action_output(100, mock_user_vkey_hex())]
    } else {
      [mock_emergency_action_output(101, mock_user_vkey_hex())]
    }

  let mint =
    to_minted_value(
      if is_emergency_token_minted {
        from_asset(
          mock_emergency_token(),
          get_emergency_token_name(mock_trade_account_address()),
          1,
        )
      } else {
        zero()
      },
    )
  let validity_range =
    mock_interval(
      None,
      Some(
        if is_time_valid {
          99
        } else {
          101
        },
      ),
    )
  Transaction {
    ..placeholder(),
    extra_signatories: extra_signatories,
    mint: mint,
    validity_range: validity_range,
    inputs: inputs,
    outputs: outputs,
  }
}

test success_initiate_emergency() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(base_initiate_emergency_test_case())
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_initiate_emergency_without_owner_signature() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(
      InitiateEmergencyTestCase {
        ..base_initiate_emergency_test_case(),
        is_owner_signed: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_initiate_emergency_without_emergency_token_minted() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(
      InitiateEmergencyTestCase {
        ..base_initiate_emergency_test_case(),
        is_emergency_token_minted: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_initiate_emergency_without_correct_input_datum() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(
      InitiateEmergencyTestCase {
        ..base_initiate_emergency_test_case(),
        is_input_datum_correct: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_initiate_emergency_without_correct_output() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(
      InitiateEmergencyTestCase {
        ..base_initiate_emergency_test_case(),
        is_output_correct: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}

test fail_initiate_emergency_with_invalid_time() {
  let output_reference = mock_utxo_ref(21)
  let datum = EmergencyIncidentInitiation { owner: mock_user_vkey_hex() }

  let redeemer = InitiateEmergencyIncident { initiate_before: 100 }
  let tx =
    mock_initiate_emergency_test_case(
      InitiateEmergencyTestCase {
        ..base_initiate_emergency_test_case(),
        is_time_valid: False,
      },
    )
  let ctx = ScriptContext { purpose: Spend(output_reference), transaction: tx }
  !trade_account_logic(
    mock_oracle_policy_id(),
    mock_user_vkey_hex(),
    mock_emergency_token(),
    datum,
    redeemer,
    ctx,
  )
}
