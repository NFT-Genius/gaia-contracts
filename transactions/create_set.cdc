import Gaia from 0xNFTContract

// This transaction is for the admin to create a new set resource
// and store it in the flow assets smart contract

// Parameters
//
// setName: the name of a new Set to be created

transaction(name: String, description: String, website: String, image: String, creator: Address, marketFee: UFix64) {
    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")

        // Create a set with the specified name
        admin.createSet(name: name, description: description, website: website,image: image, creator: creator, marketFee: marketFee)
    }
}

