/**   Generic Profile Contract
***   ========================
***
***   I am trying to figure out a generic re-usable Profile Micro-Contract
***   that any application can consume and use. It should be easy to integrate
***   this contract with any application, and as a user moves from application
***   to application this profile can come with them. A core concept here is
***   given a Flow Address, a profiles details can be publically known. This
***   should mean that if an application were to use/store the Flow address of
***   a user, than this profile could be visible, and maintained with out storing
***   a copy in an applications own databases. I believe that anytime we can move
***   a common database table into a publically accessible contract/resource is a
***   win.
***
***   It could be a little more than that too. As Flow Accounts can now have
***   multiple contracts, it could be fun to allow for these accounts to have
***   some basic information too. https://flow-view-source.com is a side project
***   of mine (qvvg) and if you are looking at an account on there, or a contract
***   deployed to an account I will make it so it pulls info from a properly
***   configured Profile Resource.
***
***
***
***   Table of Contents
***   =================
***
***   L1  - Intro
***   L24 - Table of Contents
***   L41 - General Profile Contract Info
***   L54 - How Verification Works
***   L67 - Examples
***     L78  - Initializing a Profile Resource
***     L130 - Interacting with Profile Resource (as Owner)
***     L184 - As a Verified Account, Verifiy Another Account
***     L231 - Reading a Profile Given a Flow Address
***     L265 - Reading a Multiple Profiles Given Multiple Flow Addresses
***     L299 - Checking if Flow Account is Initialized
***
***
***
***   General Profile Contract Info
***   =============================
***
***   Currently a profile consists of a couple main pieces:
***   - name – An alias the profile owner would like to be refered as.
***   - avatar - An href the profile owner would like applications to use to represent them graphically.
***   - color - A valid html color (not verified in any way) applications can use to accent and personalize the experience.
***   - info - A short description about the account.
***   - verified - A boolean value showing if the account has been verified by another verified account.
***
***
***
***
***   How verification works.
***   =======================
***
***   A profile being verified means two things:
***   - It has been verified by another verified account.
***   - It can no longer updated its name.
***
***   If I am being honest, it's mostly an experiment. I sort of want to see what
***   happens with it. Reach out to me (qvvg) on discord if you want to be verified.
***
***
***
***
***   Examples
***   ========
***
***   The following examples will include both raw cadence transactions and scripts
***   as well as how you can call them from FCL. The FCL examples are currently assuming
***   the following configuration is called somewhere in your application before the
***   the actual calls to the chain are invoked.
***
***
***
***
***   Initializing a Profile Resource
***   ===============================
***
***   Initializing should be done using the paths that the contract exposes.
***   This will lead to predictability in how applications can look up the data.
***
---Cadence Tx---

import Profile from 0xba1132bc08f82fe2

transaction {
  let address: address
  prepare(acct: AuthAccount) {
    self.address = acct.address
    if !Profile.check(self.address) {
      acct.save(<- Profile.new(), to: Profile.privatePath)
      acct.link<&Profile.Base{Profile.Public}>(Profile.publicPath, target: Profile.privatePath)
    }
  }
  post {
    Profile.check(self.address): "Account was not initialized"
  }
}

---FCL JS-SDK---

import * as fcl from "@onflow/fcl"

await fcl.send([
  fcl.proposer(fcl.authz),
  fcl.payer(fcl.authz),
  fcl.authorizations([
    fcl.authz,
  ]),
  fcl.limit(35),
  fcl.transaction`
    import Profile from 0xba1132bc08f82fe2
    
    transaction {
      prepare(acct: AuthAccount) {
        acct.save(<- Profile.new(), to: Profile.privatePath)
        acct.link<&Profile.Base{Profile.Public}>(Profile.publicPath, target: Profile.privatePath)
      }
    }
  `
]).then(fcl.decode)

----------------
***
***
***
***
***   Interacting with Profile Resource (as Owner)
***   ============================================
***
***   As the owner of a resource you can update the following:
***   - name using `.setName("MyNewName")` (as long as you arent verified)
***   - avatar using `.setAvatar("https://url.to.my.avatar")`
***   - color using `.setColor("tomato")`
***   - info using `.setInfo("I like to make things with Flow :wave:")`
***
---Cadence Tx---

import Profile from 0xba1132bc08f82fe2

transaction(name: String) {
  prepare(account: AuthAccount) {
    account
      .borrow<&{Profile.Owner}>(from: Profile.privatePath)!
      .setName(name)
  }
}

---FCL JS-SDK---

import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

await fcl.send([
  fcl.proposer(fcl.authz),
  fcl.payer(fcl.authz),
  fcl.authorizations([
    fcl.authz,
  ]),
  fcl.limit(35),
  fcl.args([
    fcl.arg("qvvg", t.String), // name
  ]),
  fcl.transaction`
    import Profile from 0xba1132bc08f82fe2
    
    transaction(name: String) {
      prepare(account: AuthAccount) {
        account
          .borrow<&{Profile.Owner}>(from: Profile.privatePath)!
          .setName(name)
      }
    }
  `
]).then(fcl.decode)

----------------
***
***
***
***
***   As a Verified Account, Verifiy Another Account
***   ==============================================
***
---Cadence Tx---

import Profile from 0xba1132bc08f82fe2

transaction(accountToBeVerified: Address) {
  prepare(accountDoingTheVerification: AuthAccount) {
    accountDoingTheVerification
      .borrow<&{Profile.Owner}>(from: Profile.privatePath)!
      .grantVerifiedStatus(accountToBeVerified)
  }
} 
---FCL JS-SDK---

import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

await fcl.send([
  fcl.proposer(fcl.authz),
  fcl.payer(fcl.authz),
  fcl.authorizations([
    fcl.authz,
  ]),
  fcl.limit(35),
  fcl.args([
    fcl.arg("0xf117a8efa34ffd58", t.Address),
  ]),
  fcl.transaction`
    import Profile from 0xba1132bc08f82fe2
    
    transaction(accountToBeVerified: Address) {
      prepare(accountDoingTheVerification: AuthAccount) {
        accountDoingTheVerification
          .borrow<&{Profile.Owner}>(from: Profile.privatePath)!
          .grantVerifiedStatus(accountToBeVerified)
      }
    } 
  `
]).then(fcl.decode)

----------------
***
***
***
***
***   Reading a Profile Given a Flow Address
***   ======================================
***
---Cadence Sc---

import Profile from 0xba1132bc08f82fe2

pub fun main(address: Address): Profile.ReadOnly? {
  return Profile.read(address)
}

---FCL JS-SDK---

import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

await fcl.send([
  fcl.args([
    fcl.arg("0xba1132bc08f82fe2", t.Address),
  ]),
  fcl.script`
    import Profile from 0xba1132bc08f82fe2
    
    pub fun main(address: Address): Profile.ReadOnly? {
      return Profile.read(address)
    }
  `
]).then(fcl.decode)

----------------
***
***
***
***
***   Reading a Multiple Profiles Given Multiple Flow Addresses
***   =========================================================
***
---Cadence Sc---

import Profile from 0xba1132bc08f82fe2

pub fun main(addresses: [Address]): {Address: Profile.ReadOnly} {
  return Profile.readMultiple(addresses)
}

---FCL JS-SDK---

import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

await fcl.send([
  fcl.args([
    fcl.arg(["0xba1132bc08f82fe2", "0xf76a4c54f0f75ce4", "0xf117a8efa34ffd58"], t.Array(t.Address)),
  ]),
  fcl.script`
    import Profile from 0xba1132bc08f82fe2
    
    pub fun main(addresses: [Address]): {Address: Profile.ReadOnly} {
      return Profile.readMultiple(addresses)
    }
  `
]).then(fcl.decode)

----------------
***
***
***
***
***   Checking if Flow Account is Initialized
***   =======================================
***
---Cadence Sc---

import Profile from 0xba1132bc08f82fe2

pub fun main(address: Address): Bool {
  return Profile.check(address)
}

---FCL JS-SDK---

import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

await fcl.send([
  fcl.args([
    fcl.arg("0xba1132bc08f82fe2", t.Address),
  ]),
  fcl.script`
    import Profile from 0xba1132bc08f82fe2
    
    pub fun main(address: Address): Bool {
      return Profile.check(address)
    }
  `
]).then(fcl.decode)

----------------
**/
pub contract Profile {
  pub let publicPath: PublicPath
  pub let privatePath: StoragePath

  pub resource interface Public {
    pub fun getName(): String
    pub fun getAvatar(): String
    pub fun getColor(): String
    pub fun getInfo(): String
    pub fun getVerified(): Bool
    pub fun asReadOnly(): Profile.ReadOnly
    
    access(contract) fun internal_setVerifiedStatus(_ val: Bool)
  }
  
  pub resource interface Owner {
    pub fun getName(): String
    pub fun getAvatar(): String
    pub fun getColor(): String
    pub fun getInfo(): String
    pub fun getVerified(): Bool
    
    pub fun setName(_ name: String) {
      pre {
        !self.getVerified():
          "Verified Profiles can't change their name."
        name.length <= 15:
          "Names must be under 15 characters long."
      }
    }
    pub fun setAvatar(_ src: String)
    pub fun setColor(_ color: String)
    pub fun setInfo(_ info: String) {
      pre {
        info.length <= 280:
          "Profile Info can at max be 280 characters long."
      }
    }
    
    pub fun grantVerifiedStatus(_ address: Address) {
      pre {
        self.getVerified():
          "Only Verified Profiles can Verify another Profile."
      }
    }
    
    pub fun revokeVerifiedStatus(_ address: Address) {
      pre {
        self.getVerified():
          "Only Verified Profiles can revoke a Verification from another Profile."
      }
    }
  }
  
  pub resource Base: Owner, Public {
    access(self) var name: String
    access(self) var avatar: String
    access(self) var color: String
    access(self) var info: String
    access(self) var verified: Bool
    
    init() {
      self.name = "Anon"
      self.avatar = ""
      self.color = "#232323"
      self.info = ""
      self.verified = false
    }
    
    pub fun getName(): String { return self.name }
    pub fun getAvatar(): String { return self.avatar }
    pub fun getColor(): String {return self.color }
    pub fun getInfo(): String { return self.info }
    pub fun getVerified(): Bool { return self.verified }
    
    pub fun setName(_ name: String) { self.name = name }
    pub fun setAvatar(_ src: String) { self.avatar = src }
    pub fun setColor(_ color: String) { self.color = color }
    pub fun setInfo(_ info: String) { self.info = info }
    
    access(contract) fun internal_setVerifiedStatus(_ val: Bool) { self.verified = val }
  
    pub fun grantVerifiedStatus(_ address: Address) {
      Profile.fetch(address).internal_setVerifiedStatus(true)
    }
    
    pub fun revokeVerifiedStatus(_ address: Address) {
      Profile.fetch(address).internal_setVerifiedStatus(false)
    }
    
    pub fun asReadOnly(): Profile.ReadOnly {
      return Profile.ReadOnly(
        address: self.owner?.address,
        name: self.getName(),
        avatar: self.getAvatar(),
        color: self.getColor(),
        info: self.getInfo(),
        verified: self.getVerified()
      )
    }
  }

  pub struct ReadOnly {
    pub let address: Address?
    pub let name: String
    pub let avatar: String
    pub let color: String
    pub let info: String
    pub let verified: Bool
    
    init(address: Address?, name: String, avatar: String, color: String, info: String, verified: Bool) {
      self.address = address
      self.name = name
      self.avatar = avatar
      self.color = color
      self.info = info
      self.verified = verified
    }
  }
  
  pub fun new(): @Profile.Base {
    return <- create Base()
  }
  
  pub fun check(_ address: Address): Bool {
    return getAccount(address)
      .getCapability<&{Profile.Public}>(Profile.publicPath)
      .check()
  }
  
  pub fun fetch(_ address: Address): &{Profile.Public} {
    return getAccount(address)
      .getCapability<&{Profile.Public}>(Profile.publicPath)
      .borrow()!
  }
  
  pub fun read(_ address: Address): Profile.ReadOnly? {
    if let profile = getAccount(address).getCapability<&{Profile.Public}>(Profile.publicPath).borrow() {
      return profile.asReadOnly()
    } else {
      return nil
    }
  }
  
  pub fun readMultiple(_ addresses: [Address]): {Address: Profile.ReadOnly} {
    let profiles: {Address: Profile.ReadOnly} = {}
    for address in addresses {
      let profile = Profile.read(address)
      if profile != nil {
        profiles[address] = profile!
      }
    }
    return profiles
  }

    
  init() {
    self.publicPath = /public/profile
    self.privatePath = /storage/profile
    
    self.account.save(<- self.new(), to: self.privatePath)
    self.account.link<&Base{Public}>(self.publicPath, target: self.privatePath)
    
    self.account
      .borrow<&Base{Owner}>(from: self.privatePath)!
      .setName("qvvg")

    self.account
      .getCapability<&{Profile.Public}>(Profile.publicPath)
      .borrow()!
      .internal_setVerifiedStatus(true)
  }
}