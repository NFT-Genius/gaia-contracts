import Gaia from 0xNFTContract

// This transaction creates a new play struct 
// and stores it in the Top Shot smart contract
// We currently stringify the metadata and instert it into the 
// transaction string, but want to use transaction arguments soon

transaction(metadata: {String: String}) {
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)
            ?? panic("No admin resource in storage")
        admin.createTemplate(metadata: metadata)
    }
}