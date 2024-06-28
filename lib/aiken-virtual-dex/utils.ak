use aiken/bytearray
use aiken/hash.{blake2b_256}
use aiken/transaction/credential.{
  Address, Inline, ScriptCredential, VerificationKeyCredential,
}
use aiken_virtual_dex/common.{convert_int_to_bytes}

pub fn get_account_token_name(count: Int) -> ByteArray {
  convert_int_to_bytes(count)
}

pub fn get_emergency_token_name(trade_account_address: Address) -> ByteArray {
  expect ScriptCredential(script_hash) =
    trade_account_address.payment_credential
  when trade_account_address.stake_credential is {
    None -> script_hash |> blake2b_256()
    Some(stake_cred) -> {
      expect Inline(credential) = stake_cred
      when credential is {
        //TODO: See if we would fix the staking part, using script or vkey
        VerificationKeyCredential(stake_hash) ->
          bytearray.concat(script_hash, stake_hash) |> blake2b_256()
        ScriptCredential(stake_hash) ->
          bytearray.concat(script_hash, stake_hash) |> blake2b_256()
      }
    }
  }
}
