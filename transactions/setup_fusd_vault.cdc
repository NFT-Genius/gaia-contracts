import FUSD from 0xFUSDContract
import FungibleToken from 0xFungibleToken

 
 transaction {
     prepare(account: AuthAccount) {
          //Init FUSD Balance
          // Create a new FUSD Vault and put it in storage
          account.save(<-FUSD.createEmptyVault(), to: /storage/fusdVault)
          // Create a public capability to the Vault that only exposes
          // the deposit function through the Receiver interface
          account.link<&FUSD.Vault{FungibleToken.Receiver}>(
            /public/fusdReceiver,
            target: /storage/fusdVault
          )
          // Create a public capability to the Vault that only exposes
          // the balance field through the Balance interface
          account.link<&FUSD.Vault{FungibleToken.Balance}>(
            /public/fusdBalance,
            target: /storage/fusdVault
          )
    }
 }