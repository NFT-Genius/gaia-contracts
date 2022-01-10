import Gaia from "../contracts/Gaia.cdc"

transaction(setID: UInt64, recipientAddr: Address) {
    let adminRef: &Gaia.Admin

    prepare(acct: AuthAccount) {
        self.adminRef = acct.borrow<&Gaia.Admin>(from: /storage/GaiaAdmin)!
    }

    execute {
        let newAdmin <- self.adminRef.createNewAdmin()
    }
}

