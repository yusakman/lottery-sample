require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localhost: {
    },
    goerli: {
      url: `${process.env.ALCHEMY_URL}`,
      accounts: [process.env.PRIV_KEY]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN
  },
};
