import GaiaOrder from 0xdaabc8918ed8cf52
import GaiaFee from 0xdaabc8918ed8cf52
import AllDay from 0x4dfd62c88d1b6462
import NFTStorefront from 0x94b06cfca1d8a476
import NonFungibleToken from 0x631e88ae7f1d7c20
import DapperUtilityCoin from 0x82ec283f88a62e65
import FungibleToken from 0x9a0766d93b6608b7

transaction (orderId: UInt64, storefrontAddress: Address) {
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}
    let paymentVault: @FungibleToken.Vault
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let tokenReceiver: &AllDay.Collection{NonFungibleToken.CollectionPublic, AllDay.MomentNFTCollectionPublic}
    let buyerAddress: Address

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability(NFTStorefront.StorefrontPublicPath)!
            .borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: orderId)
                    ?? panic("No Listing with that ID in Storefront")
        let price = self.listing.getDetails().salePrice

        let mainVault = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        self.paymentVault <- mainVault.withdraw(amount: price)

        // create a new collection if the account doesn't have one
        if acct.borrow<&AllDay.Collection>(from: AllDay.CollectionStoragePath) == nil {
            let collection <- AllDay.createEmptyCollection()
            acct.save(<-collection, to: AllDay.CollectionStoragePath)
            acct.link<&AllDay.Collection{NonFungibleToken.CollectionPublic, AllDay.MomentNFTCollectionPublic}>(
                AllDay.CollectionPublicPath,
                target: AllDay.CollectionStoragePath
            )
        }

        self.tokenReceiver = acct.getCapability(AllDay.CollectionPublicPath)
            .borrow<&AllDay.Collection{NonFungibleToken.CollectionPublic, AllDay.MomentNFTCollectionPublic}>()
            ?? panic("Cannot borrow NFT collection receiver from acct")

        self.buyerAddress = acct.address
    }

    execute {
        let item <- GaiaOrder.closeOrder(
            storefront: self.storefront,
            orderId: orderId,
            orderAddress: storefrontAddress,
            listing: self.listing,
            paymentVault: <- self.paymentVault,
            buyerAddress: self.buyerAddress
        )
        self.tokenReceiver.deposit(token: <-item)
    }
}