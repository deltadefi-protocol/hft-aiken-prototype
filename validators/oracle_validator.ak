use aiken/transaction.{ScriptContext}
use aiken_virtual_dex/types.{OracleDatum, OracleRedeemer}
use aiken_virtual_dex/validators/oracle_validator.{oracle_validator_logic}

validator {
  fn oracle_validator(
    datum: OracleDatum,
    redeemer: OracleRedeemer,
    context: ScriptContext,
  ) {
    oracle_validator_logic(datum, redeemer, context)
  }
}
