// This script reads the balance field of an account's FlowToken Balance

import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"

pub fun main(account: Address): &FlowToken.Vault{FungibleToken.Receiver} {

    let vaultRef = getAccount(account)
        .getCapability(/public/flowTokenReceiver)
        .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef
}