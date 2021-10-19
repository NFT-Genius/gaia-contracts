import Gaia from "../contracts/Gaia.cdc"

// This transaction creates a new play struct 
// and stores it in the Top Shot smart contract
// We currently stringify the metadata and instert it into the 
// transaction string, but want to use transaction arguments soon
transaction(templates: [{String: String}], setID: UInt64, authorizedAccount: Address) {
    prepare(acct: AuthAccount) {

        // borrow a reference to the admin resource
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)
            ?? panic("No admin resource in storage")
        admin.createTemplates(templates: templates, setID: setID, authorizedAccount: authorizedAccount)
    }
}