## Gaia Storefront Transactions
### Buy Item

| | | 
|---|---|
| __Name__ | Buy Item |
| __Description__ | Transaction used to purchase NFTs listed on the marketplace. |
| __Transaction Type__ | purchase |
| __File Location__ | `./transactions/buy_item.cdc` |

#### Cadence Code


```cadence
import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(listingResourceID: UInt64, storefrontAddress: Address) {
    let paymentVault: @FungibleToken.Vault
    let GaiaCollection: &Gaia.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(acct: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
                    ?? panic("No Offer with that ID in Storefront")
        let price = self.listing.getDetails().salePrice

        let mainDucVault = acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinReceiver)
            ?? panic("Cannot borrow DapperUtilityCoin vault from acct storage")
        self.paymentVault <- mainDucVault.withdraw(amount: price)

        self.GaiaCollection = acct.borrow<&Gaia.Collection{NonFungibleToken.Receiver}>(
            from: Gaia.CollectionStoragePath
        ) ?? panic("Cannot borrow NFT collection receiver from account")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )
        
        self.GaiaCollection.deposit(token: <-item)
        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}
```

### Sell Item

| | | 
|---|---|
| __Name__ | Sell Item |
| __Description__ | Transaction used to list an NFT for sale on marketplace. |
| __Transaction Type__ | purchase |
| __File Location__ | `./transactions/sell_item.cdc` |

#### Cadence Code

```cadence
import FungibleToken from "../contracts/FungibleToken.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import Gaia from "../contracts/Gaia.cdc"
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {
    let ducReceiver: Capability<&{FungibleToken.Receiver}>
    let GaiaProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(acct: AuthAccount) {
        let GaiaCollectionProviderPrivatePath = /private/GaiaCollectionProviderForNFTStorefront

        self.ducReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        assert(self.ducReceiver.borrow() != nil, message: "Missing or mis-typed DapperUtilityCoin receiver")
        
        if !acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)!.check() {
            acct.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath, target: Gaia.CollectionStoragePath)
        }

        self.GaiaProvider = acct.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(GaiaCollectionProviderPrivatePath)
        assert(self.GaiaProvider.borrow() != nil, message: "Missing or mis-typed Gaia.Collection provider")

        self.storefront = acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.ducReceiver,
            amount: saleItemPrice
        )
        self.storefront.createListing(
            nftProviderCapability: self.GaiaProvider,
            nftType: Type<@Gaia.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@DapperUtilityCoin.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
```

### Setup Account

| | | 
|---|---|
| __Name__ | Setup Account |
| __Description__ | Prepare the user account with the necessary capabilities to use the storefront and the Dapper Utility Coins  |
| __Transaction Type__ | non-purchase |
| __File Location__ | `./transactions/setup_account.cdc` |

#### Cadence Code

```cadence
import NFTStorefront from "../contracts/NFTStorefront.cdc"
import Profile from "../contracts/Profile.cdc"
import DapperUtilityCoin from "../contracts/DapperUtilityCoin.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"

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
          
          // If the account doesn't already have a Storefront
          if acct.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {
              // Create a new empty .Storefront
              let storefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
              
              // save it to the account
              acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

              // create a public capability for the .Storefront
              acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
          }

          //if user doesn't alredy have a DUC Vault
          if acct.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinReceiver) == nil {
            // Create a new DapperUtilityCoin Vault and put it in storage
            acct.save(<-DapperUtilityCoin.createEmptyVault(), to: /storage/dapperUtilityCoinReceiver)

            // Create a public capability to the Vault that only exposes
            // the deposit function through the Receiver interface
            acct.link<&{FungibleToken.Receiver}>(
                /public/dapperUtilityCoinReceiver,
                target: /storage/dapperUtilityCoinReceiver
            )

            // Create a public capability to the Vault that only exposes
            // the balance field through the Balance interface
            acct.link<&{FungibleToken.Balance}>(
                /public/dapperUtilityCoinBalance,
                target: /storage/dapperUtilityCoinReceiver
            )
        }
    }
}
```


### Setup Gaia Collection

| | | 
|---|---|
| __Name__ | Setup Gaia Collection |
| __Description__ | Create the collection that will store Gaia's NFTs in the user's account  |
| __Transaction Type__ | non-purchase |
| __File Location__ | `./transactions/setup_gaia_collection.cdc` |

#### Cadence Code

```cadence
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
```

### Remove Item

| | | 
|---|---|
| __Name__ | Remove Item |
| __Description__ | Remove an NFT from the sales listing  |
| __Transaction Type__ | purchase |
| __File Location__ | `./transactions/remove_item.cdc` |

#### Cadence Code

```cadence
import NFTStorefront from "../contracts/NFTStorefront.cdc"

transaction(listingResourceID: UInt64) {
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontManager}

    prepare(acct: AuthAccount) {
        self.storefront = acct.borrow<&NFTStorefront.Storefront{NFTStorefront.StorefrontManager}>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront.Storefront")
    }

    execute {
        self.storefront.removeListing(listingResourceID: listingResourceID)
    }
}
```