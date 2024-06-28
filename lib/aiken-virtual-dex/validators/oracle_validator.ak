use aiken/transaction.{InlineDatum, Output, ScriptContext, Spend, Transaction}
use aiken_virtual_dex/common.{
  all_key_signed, key_signed, only_minted_token, outputs_at_with,
}
use aiken_virtual_dex/types.{OracleDatum, OracleRedeemer, RotateKey, StopApp}

pub fn oracle_validator_logic(
  datum: OracleDatum,
  redeemer: OracleRedeemer,
  context: ScriptContext,
) {
  let ScriptContext { purpose, transaction } = context
  when purpose is {
    Spend(_) -> {
      let Transaction { outputs, mint, extra_signatories, .. } = transaction
      let OracleDatum { oracle_nft, oracle_address, stop_key, .. } = datum

      when redeemer is {
        RotateKey { new_operation_key, new_stop_key } -> {
          expect [own_output] =
            outputs_at_with(outputs, oracle_address, oracle_nft, "")
          expect InlineDatum(dat) = own_output.datum
          expect own_datum: OracleDatum = dat
          let datum_correct =
            own_datum == OracleDatum {
              ..datum,
              operation_key: new_operation_key,
              stop_key: new_stop_key,
            }
          all_key_signed(extra_signatories, [new_stop_key, stop_key]) && datum_correct
        }

        StopApp ->
          key_signed(extra_signatories, stop_key) && only_minted_token(
            mint,
            oracle_nft,
            "",
            -1,
          )
      }
    }
    _ -> False
  }
}
