import Gaia from "../contracts/Gaia.cdc"

transaction(name: String, description: String, website: String, imageURI: String, creator: Address, marketFee: UFix64) {
    prepare(acct: AuthAccount) {
        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")

        // Create a set with the specified name
        admin.createSet(name: name, description: description, website: website, imageURI: imageURI, creator: creator, marketFee: marketFee)
    }
}

