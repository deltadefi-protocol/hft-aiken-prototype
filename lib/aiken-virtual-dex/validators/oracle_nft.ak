use aiken/list
use aiken/transaction.{Input, Mint, OutputReference, ScriptContext, Transaction}
use aiken_virtual_dex/common.{check_policy_only_burn}
use aiken_virtual_dex/types.{MintPolarity, RBurn, RMint}

pub fn oracle_nft_logic(
  utxo_ref: OutputReference,
  redeemer: MintPolarity,
  context: ScriptContext,
) -> Bool {
  let ScriptContext { purpose, transaction } = context
  when purpose is {
    Mint(current_policy) ->
      when redeemer is {
        RMint -> {
          let Transaction { inputs, .. } = transaction
          let hash_equal =
            fn(input: Input) {
              let hash = input.output_reference
              utxo_ref == hash
            }
          let target_input_exist = list.find(inputs, hash_equal)
          when target_input_exist is {
            Some(_) -> True
            None -> False
          }
        }
        RBurn -> check_policy_only_burn(transaction.mint, current_policy)
      }
    _ -> False
  }
}
