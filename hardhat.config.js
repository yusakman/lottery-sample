require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localhost: {
    },
    // goerli: {
    //   url: process.env.ALCHEMY_API,
    //   accounts: proces.env.PRIV_KEY
    // }
  },
};
