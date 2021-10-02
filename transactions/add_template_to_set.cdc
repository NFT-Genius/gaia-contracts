import Gaia from 0xNFTContract

// This transaction is how a flow assets admin adds a created template to a set

// Parameters
//
// setID: the ID of the set to which a created template is added
// templateID: the ID of the template being added

transaction(setID: UInt64, templateID: UInt64, account: Address) {

    prepare(acct: AuthAccount) {

        // borrow a reference to the Admin resource in storage
        let admin = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)
            ?? panic("Could not borrow a reference to the Admin resource")
        
        // Borrow a reference to the set to be added to
        let setRef = admin.borrowSet(setID: setID, authorizedAccount: account)

        // Add the specified template ID
        setRef.addTemplate(templateID: templateID)
    }
}