import fcl from '@onflow/fcl';
import t from '@onflow/types';
import FlowService from './flow-service';
import { loadScript } from '../utils/load-script';

class AccountService extends FlowService {
  constructor() {
    super();
    this.transactions = {
      setupFUSDVault: loadScript('transactions/setup_fusd_vault.cdc'),
      getBalance: loadScript('transactions/get_fusd_balance.cdc')
    };
  }
  async getFUSDBalance(address) {
    const { getBalance } = this.transactions;
    return this.executeScript({
      script: getBalance,
      args: [fcl.arg(address, t.Address)]
    });
  }

  async setupFUSD() {
    const { setupFUSDVault } = this.transactions;
    try {
      const tx = await this.sendTx({
        transaction: setupFUSDVault
      });
      console.log(tx);
      return tx;
    } catch (error) {
      console.log('Error on FUSD Vault setup');
      if (error instanceof Error || !error.includes('Error Code: 1101')) throw error;
    }
  }
}

export default new AccountService();
