import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox"; // Gói tổng hợp các plugin cần thiết
import * as dotenv from "dotenv";

dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_ADDRESS || process.env.PRIVATE_ADDRESS;
const RPC_URL = process.env.RPC_URL;

if (!PRIVATE_KEY) {
  console.warn("Privae key bi null kìa ");
}
if (!RPC_URL) {
  console.warn("RPC Null kìa");
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28", 
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    sepolia: {
      url: RPC_URL || "", 
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
    },
    pione: {
      url: "https://rpc.zeroscan.org",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 5080,
    },
  },
  
  etherscan: {
    
  },

  sourcify: {
    enabled: true,
  },
};

export default config;