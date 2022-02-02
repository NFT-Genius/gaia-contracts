import GaiaOrder from 0xdaabc8918ed8cf52
import GaiaFee from 0xdaabc8918ed8cf52
import AllDay from 0x4dfd62c88d1b6462
import NFTStorefront from 0x94b06cfca1d8a476
import NonFungibleToken from 0x631e88ae7f1d7c20
import DapperUtilityCoin from 0x82ec283f88a62e65
import FungibleToken from 0x9a0766d93b6608b7

transaction(nftID: UInt64, price: UFix64, royalties: {Address: UFix64}) {
    let nftProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront
    let oldListings: [&NFTStorefront.Listing{NFTStorefront.ListingPublic}]
    let orderAddress: Address

    prepare(acct: AuthAccount) {
        // verify/init nft provider
        let nftProviderPath = /private/AllDayNFTProviderForNFTStorefront
        if !acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftProviderPath)!.check() {
            acct.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftProviderPath, target: AllDay.CollectionStoragePath)
        }
        self.nftProvider = acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(nftProviderPath)!
        assert(self.nftProvider.borrow() != nil, message: "Missing or mis-typed nft collection provider")

        // verify/init storefront
        if acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {
            let storefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
            acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)
            acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
        }
        self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")

        // order address same as proposer
        self.orderAddress = acct.address

        // verify duc vault 
        assert(acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) != nil, message: "Cannot borrow DapperUtilityCoin vault from acct storage")

        // find all existing listings with matching nft id 
        self.oldListings = []
        let listingIDs = self.storefront.getListingIDs()
        for id in listingIDs {
            let listing = self.storefront.borrowListing(listingResourceID: id)! 
            if listing.getDetails().nftID == nftID {
                self.oldListings.append(listing)
            }
        }
    }

    execute {
        // remove old listings
        for listing in self.oldListings {
            GaiaOrder.removeOrder(
                storefront: self.storefront,
                orderId: listing.uuid,
                orderAddress: self.orderAddress,
                listing: listing
            )
        }

        let royaltiesPart: [GaiaOrder.PaymentPart] = []
        let extraCuts: [GaiaOrder.PaymentPart] = []

        for k in royalties.keys {
            royaltiesPart.append(GaiaOrder.PaymentPart(address: k, rate: royalties[k]!))
        }

        GaiaOrder.addOrder(
            storefront: self.storefront,
            nftProvider: self.nftProvider,
            nftType: Type<@AllDay.NFT>(), // specify nft type
            nftId: nftID,
            vaultPath: /public/dapperUtilityCoinReceiver, // specify public ft vault path
            vaultType: Type<@DapperUtilityCoin.Vault>(), // specify ft token
            price: price,
            extraCuts: extraCuts,
            royalties: royaltiesPart
        )
    }
}