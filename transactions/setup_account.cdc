import NFTStorefront from "../contracts/NFTStorefront.cdc"
import Profile from "../contracts/Profile.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"
import Gaia from "../contracts/Gaia.cdc"
// This transaction installs the Storefront ressource in an account.
transaction {
    let address: Address
    prepare(acct: AuthAccount) {
        self.address = acct.address
        // Init Profile
        if (!Profile.check(self.address)) {
            // This creates and stores the Profile in the users account
            acct.save(<- Profile.new(), to: Profile.privatePath)
            // This creates the public capability that lets applications read the profiles info
            acct.link<&Profile.Base{Profile.Public}>(Profile.publicPath, target: Profile.privatePath)
        }

        // Setup gaia collection if the account doesn't have one
        if acct.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath) == nil {
            let collection <- Gaia.createEmptyCollection() as! @Gaia.Collection
            acct.save(<-collection, to: Gaia.CollectionStoragePath)
            acct.link<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath, target: Gaia.CollectionStoragePath)
        }
        
        // If the account doesn't already have a Storefront
        if acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {
            // Create a new empty .Storefront
            let storefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
            
            // save it to the account
            acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)
            // create a public capability for the .Storefront
            acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
        }
        
        if acct.borrow<&Gaia.Collection>(from: Gaia.CollectionStoragePath) == nil {
            let collection <- Gaia.createEmptyCollection() as! @Gaia.Collection
            acct.save(<-collection, to: Gaia.CollectionStoragePath)
            acct.link<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath, target: Gaia.CollectionStoragePath)
        }
    }
}
 