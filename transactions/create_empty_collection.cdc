import Gaia from "../contracts/Gaia.cdc";

transaction {
    let address: Address

    prepare(account: AuthAccount) {
      self.address = account.address        
        
        if account.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath) == nil {
            let collection <- Gaia.createEmptyCollection() as! @Gaia.Collection
            account.save(<-collection, to: Gaia.CollectionStoragePath)
            account.link<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath, target: Gaia.CollectionStoragePath)
        }
  }
}