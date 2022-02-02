require("@nomiclabs/hardhat-waffle");

const config = require("./config.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    hardhat: {
    },
    mumbai: {
      networkId: 80001,
      url: "https://matic-testnet-archive-rpc.bwarelabs.com",
      accounts: config.privateKeys,
    }
  },
};
