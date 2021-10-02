import Gaia from 0xNFTContract

// This transaction sets up an account to use Flow Assets
// by storing an empty nft collection and creating
// a public capability for it

transaction {

    prepare(acct: AuthAccount) {

        // First, check to see if a moment collection already exists
        if acct.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath) == nil {

            // create a new Gaia Collection
            let collection <- Gaia.createEmptyCollection() as! @Gaia.Collection

            // Put the new Collection in storage
            acct.save(<-collection, to: Gaia.CollectionStoragePath)

            // create a public capability for the collection
            acct.link<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath, target: Gaia.CollectionStoragePath)
        }
    }
}