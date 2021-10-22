import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(listingResourceID: UInt64, storefrontAddress: Address, expectedPrice: UFix64, buyerAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let buyerGaiaCollection: &Gaia.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Listing{NFTStorefront.ListingPublic}>(
                NFTStorefront.StorefrontStoragePath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
                    ?? panic("No Offer with that ID in Storefront")
        let salePrice = self.listing.getDetails().salePrice

        let mainDucVault = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinReceiver)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        self.paymentVault <- mainDucVault.withdraw(amount: salePrice)

        if (expectedPrice != salePrice) {
            panic("Expected price does not match sale price")
        }

        let mainDucValue = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinReceiver)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        self.paymentVault <- mainDucValue.withdraw(amount: salePrice)

        self.buyerGaiaCollection = getAccount(buyerAddress)
            .getCapability<&Gaia.Collection{NonFungibleToken.Receiver}>(
                Gaia.CollectionPublicPath
            )
            .borrow()
            ?? panic("Could not borrow Gaia Collection from provided address")

        self.GaiaCollection = acct.borrow<&Gaia.Collection{NonFungibleToken.Receiver}>(
            from: Gaia.CollectionStoragePath
        ) ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )
        
        self.buyerGaiaCollection.deposit(token: <-item)
    }
}