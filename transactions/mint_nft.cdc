import Gaia from "../contracts/Gaia.cdc"

// This transaction is what an admin would use to mint a single new moment
// and deposit it in a user's collection

// Parameters
//
// setID: the ID of a set containing the target play
// templateID: the ID of a play from which a new moment is minted
// recipientAddr: the Flow address of the account receiving the newly minted moment

transaction(setID: UInt64, templateID: UInt64, recipientAddr: Address) {
    // local variable for the admin reference
    let adminRef: &Gaia.Admin

    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        self.adminRef = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)!
    }

    execute {
        // Borrow a reference to the specified set
        let setRef = self.adminRef.borrowSet(setID: setID, authorizedAccount: recipientAddr)

        // Mint a new NFT
        let nft <- setRef.mintNFT(templateID: templateID)

        // get the public account object for the recipient
        let recipient = getAccount(recipientAddr)

        // get the Collection reference for the receiver
        let receiverRef = recipient.getCapability(Gaia.CollectionPublicPath).borrow<&{Gaia.CollectionPublic}>()
            ?? panic("Cannot borrow a reference to the recipient's moment collection")

        // deposit the NFT in the receivers collection
        receiverRef.deposit(token: <-nft)
    }
}