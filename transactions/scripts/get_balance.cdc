// This script reads the balance field of an account's FlowToken Balance

import FungibleToken from "../../contracts/FungibleToken.cdc"
import DapperUtilityCoin from "../../contracts/DapperUtilityCoin.cdc"

pub fun main(account: Address): UFix64 {

    let vaultRef = getAccount(account)
        .getCapability(/public/dapperUtilityCoinBalance)
        .borrow<&DapperUtilityCoin.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}