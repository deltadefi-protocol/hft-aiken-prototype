use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{Address}
use aiken_virtual_dex/types.{ChangeAccountDatum, ChangeAccountRedeemer}
use aiken_virtual_dex/validators/change_account.{change_account_logic}

validator(owner: ByteArray, trade_account_address: Address) {
  fn change_account(
    datum: ChangeAccountDatum,
    redeemer: ChangeAccountRedeemer,
    context: ScriptContext,
  ) {
    change_account_logic(owner, trade_account_address, datum, redeemer, context)
  }
}
