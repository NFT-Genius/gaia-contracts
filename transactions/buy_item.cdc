import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"
transaction(listingResourceID: UInt64, storefrontAddress: Address, expectedPrice: UFix64, buyerAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let buyerGaiaCollection: &{Gaia.CollectionPublic}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}
    let balanceBeforeTransfer: UFix64
    let mainDucVault: &DapperUtilityCoin.Vault
    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
                    ?? panic("No Offer with that ID in Storefront")
        let salePrice = self.listing.getDetails().salePrice
        self.mainDucVault = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        
        self.balanceBeforeTransfer = self.mainDucVault.balance
        self.paymentVault <- self.mainDucVault.withdraw(amount: salePrice)
        
        if (expectedPrice != salePrice) {
            panic("Expected price does not match sale price")
        }
        
        self.buyerGaiaCollection = getAccount(buyerAddress)
            .getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow Gaia Collection from provided address")
    }
    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )
        
        self.buyerGaiaCollection.deposit(token: <-item)
        if self.mainDucVault.balance != self.balanceBeforeTransfer {
            panic("DUC leakage")
        }
    }
}