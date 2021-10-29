import Gaia from "../contracts/Gaia.cdc";

// This transaction configures an account to hold assets.
transaction {

    let address: Address

    prepare(account: AuthAccount) {
      //INITIALIZING PARAMS
      self.address = account.address
        
        // First, check to see if a moment collection already exists
        if account.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath) == nil {
            // create a new Gaia Collection
            let collection <- Gaia.createEmptyCollection() as! @Gaia.Collection
            // Put the new Collection in storage
            account.save(<-collection, to: Gaia.CollectionStoragePath)
            // create a public capability for the collection
            account.link<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath, target: Gaia.CollectionStoragePath)
        }
  }
}