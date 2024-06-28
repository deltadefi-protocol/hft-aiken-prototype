use aiken/transaction.{ScriptContext}
use aiken_virtual_dex/types.{EmergencyTokenMintingPolarity}
use aiken_virtual_dex/validators/emergency_token.{emergency_token_logic}

validator {
  fn emergency_token(
    redeemer: EmergencyTokenMintingPolarity,
    context: ScriptContext,
  ) -> Bool {
    emergency_token_logic(redeemer, context)
  }
}
