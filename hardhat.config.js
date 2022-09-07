require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.16",
  networks: {
    hardhat: {
      forking: {
        url: process.env.RPC_URL,
      }
    }
  }
};
