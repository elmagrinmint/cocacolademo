import '@nomiclabs/hardhat-truffle5';
import '@typechain/hardhat';
import solcconfig from './solcconfig.json';
import 'hardhat-watcher';
import '@nomiclabs/hardhat-solhint';
import 'solidity-coverage';

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: solcconfig.version,
    settings: {
      optimizer: {
        enabled: solcconfig.optimizer.enabled,
        runs: solcconfig.optimizer.runs,
      },
    },
  },
  typechain: {
    outDir: 'types/truffle-contracts',
    target: 'truffle-v5',
  },
  networks: {
    hardhat: {
      chainId: 1337,
      gasPrice: 0,
      allowUnlimitedContractSize: true,
      blockGasLimit: 0x1fffffffffffff,
      accounts: {
        mnemonic: 'twelve hidden pole trash great learn duck song observe message dash rather',
      },
    },
  },
  watcher: {
    test: {
      tasks: [{ command: 'test' }],
      files: ['./test/**/*', './contracts/**/*'],
      verbose: true,
    },
  },
};
