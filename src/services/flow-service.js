import fcl from '@onflow/fcl';
import sdk from '@onflow/sdk';
import { ec as EC } from 'elliptic';
import SHA3 from 'sha3';
import {
  ACCESS_NODE,
  NFT_INTERFACE,
  NFT_CONTRACT,
  NFT_MARKET_CONTRACT,
  MINTER_ADDRESS,
  MINTER_PRIVATE_KEY,
  MINTER_ACCOUNT_INDEX,
  FUSD_CONTRACT,
  FUNGIBLE_TOKEN,
  DUC_CONTRACT
} from '../config';

const ec = new EC('p256');

class FlowService {
  constructor() {
    fcl
      .config()
      .put('accessNode.api', ACCESS_NODE)
      .put('0xNFTInterface', NFT_INTERFACE)
      .put('0xNFTContract', NFT_CONTRACT)
      .put('0xNFTMarket', NFT_MARKET_CONTRACT)
      .put('0xFUSDContract', FUSD_CONTRACT)
      .put('0xFungibleToken', FUNGIBLE_TOKEN)
      .put('0xDuc', DUC_CONTRACT);
  }
  async getAccount(addr) {
    const { account } = await fcl.send([fcl.getAccount(addr)]);
    return account;
  }

  signWithKey(privateKey, msg) {
    const key = ec.keyFromPrivate(Buffer.from(privateKey, 'hex'));
    const sig = key.sign(this.hashMsg(msg));
    const n = 32;
    const r = sig.r.toArrayLike(Buffer, 'be', n);
    const s = sig.s.toArrayLike(Buffer, 'be', n);
    return Buffer.concat([r, s]).toString('hex');
  }

  hashMsg(msg) {
    const sha = new SHA3(256);
    sha.update(Buffer.from(msg, 'hex'));
    return sha.digest();
  }

  async sendTx({ transaction, args }) {
    const signingFunction = data => {
      return {
        addr: MINTER_ADDRESS,
        keyId: MINTER_ACCOUNT_INDEX,
        signature: this.signWithKey(MINTER_PRIVATE_KEY, data.message)
      };
    };
    const response = await fcl.send([
      fcl.transaction(fcl.cdc`${transaction}`),
      fcl.args(args),
      fcl.proposer(sdk.authorization(MINTER_ADDRESS, signingFunction, 0)),
      fcl.authorizations([sdk.authorization(MINTER_ADDRESS, signingFunction, 0)]),
      fcl.payer(sdk.authorization(MINTER_ADDRESS, signingFunction, 0)),
      fcl.limit(9999)
    ]);
    return fcl.tx(response).onceSealed();
  }

  async executeScript({ script, args }) {
    return fcl.send([fcl.script`${script}`, fcl.args(args)]).then(fcl.decode);
  }
}

export default FlowService;
