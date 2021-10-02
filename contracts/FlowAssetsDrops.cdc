import NonFungibleToken from "./NonFungibleToken.cdc"
import Gaia from "./GaiaDrops.cdc"

// GaiaDrops
pub contract GaiaDrops {

    // Events
    //
    pub event ContractInitialized()
    pub event DropCreated(dropID: UInt64, name: String, creator: Address, marketFee: UFix64)
    pub event DropLocked(dropID: UInt64)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath



    access(self) var dropDatas: {UInt64: DropData}
    access(self) var drops: @{UInt64: Drop}


    pub var nextDropID: UInt64

    pub struct DropData {

        // Unique ID for the Set
        pub let dropID: UInt64

        // Name of the Set
        pub let name: String

        // Account address of the set creator
        pub let creator: Address

        // Stores all the metadata about the template as a string mapping
        // This is not the long term way NFT metadata will be stored.
        pub let marketFee: UFix64

        init(name: String, creator: Address, marketFee: UFix64) {
            pre {
                name.length > 0: "New set name cannot be empty"
            }

            self.dropID = GaiaDrops.nextDropID
            self.name = name
            self.creator = creator
            self.marketFee = marketFee

            // Increment the dropID so that it isn't used again
            GaiaDrops.nextDropID = GaiaDrops.nextDropID + 1 as UInt64

            emit DropCreated(dropID: self.dropID, name: name, creator: creator, marketFee: marketFee)
        }
    }


    pub resource Drop {

        pub let dropID: UInt64
        pub let templatesToMint: [UInt64]
        pub let price: UFix64
        pub let dropSupply: UInt32
        pub var locked: Bool



        init(name: String, creator: Address, templatesToMint: [UInt64], price: UFix64) {
            self.dropID = GaiaDrops.nextDropID
            self.templatesToMint = templatesToMint
            self.price = price
            self.dropSupply = 
            // Create a new SetData for this Set and store it in contract storage
            GaiaDrops.dropDatas[self.dropID] = DropData(name: name, creator: creator, marketFee: marketFee)
        }

        // lock() locks the Set so that no more Templates can be added to it
        //
        // Pre-Conditions:
        // The Set should not be locked
        pub fun lock() {
            if !self.locked {
                self.locked = true
                emit DropLocked(dropID: self.dropID)
            }
        }

        // mintNFT mints a new NFT and returns the newly minted NFT
        // 
        // Parameters: templateID: The ID of the Template that the NFT references
        //
        // Pre-Conditions:
        // The Template must exist in the Set and be allowed to mint new NFTs
        //
        // Returns: The NFT that was minted
        // 
        pub fun mintNFT(templateID: UInt64): @NFT {
            pre {
                self.lockedTemplates[templateID] != nil: "Cannot mint the NFT: This template doesn't exist."
                !self.lockedTemplates[templateID]!: "Cannot mint the NFT from this template: This template has been locked."
            }

            // Gets the number of NFTs that have been minted for this Template
            // to use as this NFT's serial number
            let numInTemplate = self.numberMintedPerTemplate[templateID]!

            // Mint the new moment
            let newNFT: @NFT <- create NFT(mintNumber: numInTemplate + 1 as UInt64,
                                              templateID: templateID,
                                              dropID: self.dropID)

            // Increment the count of Moments minted for this Play
            self.numberMintedPerTemplate[templateID] = numInTemplate + 1 as UInt64

            return <-newNFT
        }

        // batchMintNFT mints an arbitrary quantity of NFTs 
        // and returns them as a Collection
        //
        // Parameters: templateID: the ID of the Template that the NFTs are minted for
        //             quantity: The quantity of NFTs to be minted
        //
        // Returns: Collection object that contains all the NFTs that were minted
        //
        pub fun batchMintNFT(templateID: UInt64, quantity: UInt64): @Collection {
            let newCollection <- create Collection()

            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <-self.mintNFT(templateID: templateID))
                i = i + 1 as UInt64
            }

            return <-newCollection
        }
    }


    pub struct NFTData {

        // The ID of the Set that the Moment comes from
        pub let dropID: UInt64

        // The ID of the Play that the Moment references
        pub let templateID: UInt64

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        pub let mintNumber: UInt64

        init(dropID: UInt64, templateID: UInt64, mintNumber: UInt64) {
            self.dropID = dropID
            self.templateID = templateID
            self.mintNumber = mintNumber
        }

    }

    // NFT
    // A Flow Asset as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        // Struct of NFT metadata
        pub let data: NFTData

        // initializer
        //
        init(mintNumber: UInt64, templateID: UInt64, dropID: UInt64) {
            // Increment the global Moment IDs
            GaiaDrops.totalSupply = GaiaDrops.totalSupply + 1 as UInt64

            self.id = GaiaDrops.totalSupply

            // Set the metadata struct
            self.data = NFTData(dropID: dropID, templateID: templateID, mintNumber: mintNumber)

            emit Minted(asdropID: self.id, templateID: templateID, dropID: self.data.dropID, mintNumber: self.data.mintNumber)
        }
    }

    // Admin is a special authorization resource that 
    // allows the owner to perform important functions to modify the 
    // various aspects of the Templates, Sets, and NFTs
    //
    pub resource Admin {

        // createTemplate creates a new Template struct 
        // and stores it in the Templates dictionary in the TopShot smart contract
        //
        // Parameters: metadata: A dictionary mapping metadata titles to their data
        //                       example: {"Name": "John Doe", "DoB": "4/14/1990"}
        //
        // Returns: the ID of the new Template object
        //
        pub fun createTemplate(metadata: {String: String}): UInt64 {
            // Create the new Template
            var newTemplate = Template(metadata: metadata)
            let newID = newTemplate.templateID

            // Store it in the contract storage
            GaiaDrops.templateDatas[newID] = newTemplate

            return newID
        }

        // createSet creates a new Set resource and stores it
        // in the sets mapping in the contract
        //
        // Parameters: name: The name of the Set
        //
        pub fun createSet(name: String, creator: Address, marketFee: UFix64) {
            // Create the new Set
            var newSet <- create Set(name: name, creator: creator, marketFee: marketFee)

            // Store it in the sets mapping field
            GaiaDrops.sets[newSet.dropID] <-! newSet
        }

        // borrowSet returns a reference to a set in the contract
        // so that the admin can call methods on it
        //
        // Parameters: dropID: The ID of the Set that you want to
        // get a reference to
        //
        // Returns: A reference to the Set with all of the fields
        // and methods exposed
        //
        pub fun borrowSet(dropID: UInt64): &Set {
            pre {
                GaiaDrops.sets[dropID] != nil: "Cannot borrow Set: The Set doesn't exist"
            }
            
            // Get a reference to the Set and return it
            // use `&` to indicate the reference to the object and type
            return &GaiaDrops.sets[dropID] as &Set
        }

        // createNewAdmin creates a new Admin resource
        //
        pub fun createNewAdmin(): @Admin {
            return <-create Admin()
        }
    }

    // This is the interface that users can cast their Gaia Collection as
    // to allow others to deposit Gaia into their Collection. It also allows for reading
    // the details of Gaia in the Collection.
    pub resource interface GaiaCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowFlowAsset(id: UInt64): &GaiaDrops.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow FlowAsset reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of FlowAsset NFTs owned by an account
    //
    pub resource Collection: GaiaCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // batchWithdraw withdraws multiple tokens and returns them as a Collection
        //
        // Parameters: ids: An array of IDs to withdraw
        //
        // Returns: @NonFungibleToken.Collection: A collection that contains
        //                                        the withdrawn NFTs
        //
        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create a new empty Collection
            var batchCollection <- create Collection()
            
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            
            // Return the withdrawn tokens
            return <-batchCollection
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @GaiaDrops.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowFlowAsset
        // Gets a reference to an NFT in the collection as a FlowAsset,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the FlowAsset.
        //
        pub fun borrowFlowAsset(id: UInt64): &GaiaDrops.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &GaiaDrops.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // getAllTemplates returns all the plays in topshot
    //
    // Returns: An array of all the plays that have been created
    pub fun getAllTemplates(): [GaiaDrops.Template] {
        return GaiaDrops.templateDatas.values
    }

    // getTemplateMetaData returns all the metadata associated with a specific Template
    // 
    // Parameters: templateID: The id of the Template that is being searched
    //
    // Returns: The metadata as a String to String mapping optional
    pub fun getTemplateMetaData(templateID: UInt64): {String: String}? {
        return self.templateDatas[templateID]?.metadata
    }

    // getTemplateMetaDataByField returns the metadata associated with a 
    //                        specific field of the metadata
    //                        Ex: field: "Name" will return something
    //                        like "John Doe"
    // 
    // Parameters: templateID: The id of the Template that is being searched
    //             field: The field to search for
    //
    // Returns: The metadata field as a String Optional
    pub fun getTemplateMetaDataByField(templateID: UInt64, field: String): String? {
        // Don't force a revert if the playID or field is invalid
        if let template = GaiaDrops.templateDatas[templateID] {
            return template.metadata[field]
        } else {
            return nil
        }
    }

    // getSetName returns the name that the specified Set
    //            is associated with.
    // 
    // Parameters: dropID: The id of the Set that is being searched
    //
    // Returns: The name of the Set
    pub fun getSetName(dropID: UInt64): String? {
        // Don't force a revert if the dropID is invalid
        return GaiaDrops.setDatas[dropID]?.name
    }

    pub fun getSetMarketFee(dropID: UInt64): UFix64? {
        // Don't force a revert if the dropID is invalid
        return GaiaDrops.setDatas[dropID]?.marketFee
    }

    // getdropIDsByName returns the IDs that the specified Set name
    //                 is associated with.
    // 
    // Parameters: setName: The name of the Set that is being searched
    //
    // Returns: An array of the IDs of the Set if it exists, or nil if doesn't
    pub fun getdropIDsByName(setName: String): [UInt64]? {
        var dropIDs: [UInt64] = []

        // Iterate through all the setDatas and search for the name
        for setData in GaiaDrops.setDatas.values {
            if setName == setData.name {
                // If the name is found, return the ID
                dropIDs.append(setData.dropID)
            }
        }

        // If the name isn't found, return nil
        // Don't force a revert if the setName is invalid
        if dropIDs.length == 0 {
            return nil
        } else {
            return dropIDs
        }
    }

    // getTemplatesInSet returns the list of Template IDs that are in the Set
    // 
    // Parameters: dropID: The id of the Set that is being searched
    //
    // Returns: An array of Template IDs
    pub fun getTemplatesInSet(dropID: UInt64): [UInt64]? {
        // Don't force a revert if the dropID is invalid
        return GaiaDrops.sets[dropID]?.templates
    }

    // isSetTemplateLocked returns a boolean that indicates if a Set/Template combo
    //                  is locked.
    //                  If an template is locked, it still remains in the Set,
    //                  but NFTs can no longer be minted from it.
    // 
    // Parameters: dropID: The id of the Set that is being searched
    //             playID: The id of the Play that is being searched
    //
    // Returns: Boolean indicating if the template is locked or not
    pub fun isSetTemplateLocked(dropID: UInt64, templateID: UInt64): Bool? {
        // Don't force a revert if the set or play ID is invalid
        // Remove the set from the dictionary to get its field
        if let setToRead <- GaiaDrops.sets.remove(key: dropID) {

            // See if the Play is retired from this Set
            let locked = setToRead.lockedTemplates[templateID]

            // Put the Set back in the contract storage
            GaiaDrops.sets[dropID] <-! setToRead

            // Return the retired status
            return locked
        } else {

            // If the Set wasn't found, return nil
            return nil
        }
    }

    // isSetLocked returns a boolean that indicates if a Set
    //             is locked. If it's locked, 
    //             new Plays can no longer be added to it,
    //             but NFTs can still be minted from Templates the set contains.
    // 
    // Parameters: dropID: The id of the Set that is being searched
    //
    // Returns: Boolean indicating if the Set is locked or not
    pub fun isSetLocked(dropID: UInt64): Bool? {
        // Don't force a revert if the dropID is invalid
        return GaiaDrops.sets[dropID]?.locked
    }

    // getTotalMinted return the number of NFTS that have been 
    //                        minted from a certain set and template.
    //
    // Parameters: dropID: The id of the Set that is being searched
    //             templateID: The id of the Template that is being searched
    //
    // Returns: The total number of NFTs 
    //          that have been minted from an set and template
    pub fun getTotalMinted(dropID: UInt64, templateID: UInt64): UInt64? {
        // Don't force a revert if the Set or play ID is invalid
        // Remove the Set from the dictionary to get its field
        if let setToRead <- GaiaDrops.sets.remove(key: dropID) {

            // Read the numMintedPerPlay
            let amount = setToRead.numberMintedPerTemplate[templateID]

            // Put the Set back into the Sets dictionary
            GaiaDrops.sets[dropID] <-! setToRead

            return amount
        } else {
            // If the set wasn't found return nil
            return nil
        }
    }

    // fetch
    // Get a reference to a FlowAsset from an account's Collection, if available.
    // If an account does not have a GaiaDrops.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &GaiaDrops.NFT? {
        let collection = getAccount(from)
            .getCapability(GaiaDrops.CollectionPublicPath)!
            .borrow<&GaiaDrops.Collection{GaiaDrops.GaiaCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust GaiaDrops.Collection.borowFlowAsset to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowFlowAsset(id: itemID)
    }

    // initializer
    //
    init() {
        // Set our named paths
        //FIXME: REMOVE SUFFIX BEFORE RELEASE
        self.CollectionStoragePath = /storage/flowAssetsCollection002
        self.CollectionPublicPath = /public/flowAssetsCollection002

        // Initialize contract fields
        self.templateDatas = {}
        self.setDatas = {}
        self.sets <- {}
        self.nextTemplateID = 1
        self.nextDropID = 1
        self.totalSupply = 0

        // Put a new Collection in storage
        self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)

        // Create a public capability for the Collection
        self.account.link<&{GaiaCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        // Put the Minter in storage
        self.account.save<@Admin>(<- create Admin(), to: /storage/GaiaAdmin)
    }
}
