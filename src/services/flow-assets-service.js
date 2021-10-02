import fcl from '@onflow/fcl';
import t from '@onflow/types';
import FlowService from './flow-service';
import { loadScript } from '../utils/load-script';

class GaiaService extends FlowService {
  constructor() {
    super();
    this.transactions = {
      mint: loadScript('transactions/mint_nft.cdc'),
      createSet: loadScript('transactions/create_set.cdc'),
      createTemplate: loadScript('transactions/create_template.cdc'),
      addTemplateToSet: loadScript('transactions/add_template_to_set.cdc'),
      getBalance: loadScript('transactions/get_fusd_balance.cdc')
    };
  }

  async mint(setID, templateID, recipientAddr) {
    const { mint } = this.transactions;
    return this.sendTx({
      transaction: mint,
      args: [
        fcl.arg(parseInt(setID, 10), t.UInt64),
        fcl.arg(parseInt(templateID, 10), t.UInt64),
        fcl.arg(fcl.withPrefix(recipientAddr), t.Address)
      ]
    });
  }

  async createSet(name, description, website, image, creator, marketFee) {
    const { createSet } = this.transactions;
    return this.sendTx({
      transaction: createSet,
      args: [
        fcl.arg(name, t.String),
        fcl.arg(description, t.String),
        fcl.arg(website, t.String),
        fcl.arg(image, t.String),
        fcl.arg(creator, t.Address),
        fcl.arg(marketFee, t.UFix64)
      ]
    });
  }
  async getFUSDBalance(address) {
    const { getBalance } = this.transactions;
    return this.executeScript({
      script: getBalance,
      args: [fcl.arg(address, t.Address)]
    });
  }

  async createTemplate(setID, creator, metadata) {
    const { createTemplate } = this.transactions;

    const parsedMetadata = Object.entries(metadata).map(([key, value]) => ({
      key,
      value
    }));

    return this.sendTx({
      transaction: createTemplate,
      args: [fcl.arg(parsedMetadata, t.Dictionary({ key: t.String, value: t.String }))]
    });
  }

  async addTemplateToSet(templateID, setID, creator) {
    const { addTemplateToSet } = this.transactions;
    try {
      const tx = await this.sendTx({
        transaction: addTemplateToSet,
        args: [
          fcl.arg(parseInt(setID, 10), t.UInt64),
          fcl.arg(parseInt(templateID, 10), t.UInt64),
          fcl.arg(fcl.withPrefix(creator), t.Address)
        ]
      });
      return tx;
    } catch (error) {
      if (error instanceof Error || !error.includes('Error Code: 1101')) throw error;
    }
  }
}

export default new GaiaService();
