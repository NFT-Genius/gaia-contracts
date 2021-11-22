import Gaia from "../contracts/Gaia.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

// This transaction transfers a Kitty Item from one account to another.
transaction(recipient: Address, assetID: UInt64) {
    prepare(signerAcct: AuthAccount) {
        
        // get the recipients public account object
        let recipientAcct = getAccount(recipient)

        // borrow a reference to the signer's NFT collection
        let signerCollectionRef = signerAcct.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        // borrow a public reference to the receivers collection
        let depositRef = recipientAcct.getCapability(Gaia.CollectionPublicPath)
              .borrow<&{Gaia.CollectionPublic}>()!  

        // withdraw the NFT from the owner's collection
        let nft <- signerCollectionRef.withdraw(withdrawID: assetID)

        // Deposit the NFT in the recipient's collection
        depositRef.deposit(token: <-nft)
    }
}